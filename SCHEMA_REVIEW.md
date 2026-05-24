# Schema & Models — Production Readiness Review

> **Date:** 2026-03-11
> **Files reviewed:** `backend/app/schemas.py`, `backend/app/models.py`

---

## Critical Issues

### 1. No Input Validation on Pydantic Schemas

All string and numeric fields accept arbitrary values with no constraints. This is the single biggest gap.

**Affected schemas:** `UserCreate`, `ChangePassword`, `FieldCreate`, `KrishiYieldInput`, `SensorData`, `YieldInput`, `FertilizerRecommendationInput`, `KrishiChatInput`

| Field               | Current               | Required                                            |
| ------------------- | --------------------- | --------------------------------------------------- |
| `email`             | `str`                 | `EmailStr` (from `pydantic`) with format validation |
| `password`          | `str`                 | `min_length=8`, `max_length=128`                    |
| `name`              | `str`                 | `min_length=1`, `max_length=100`                    |
| `crop`              | `str`                 | `min_length=1`, `max_length=100`                    |
| `lat`               | `float`               | `ge=-90, le=90`                                     |
| `lon`               | `float`               | `ge=-180, le=180`                                   |
| `soil_pH`           | `float` (default 6.5) | `ge=0, le=14`                                       |
| `humidity_mean_pct` | `float`               | `ge=0, le=100`                                      |
| `seasonal_rain_mm`  | `float`               | `ge=0`                                              |
| `moisture`          | `float`               | `ge=0, le=100`                                      |
| `temperature`       | `float`               | Sensible range, e.g. `ge=-50, le=60`                |

**Example fix:**

```python
from pydantic import BaseModel, Field, EmailStr

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
```

---

### 2. Untyped `dict` in `KrishiChatInput`

```python
yield_context: Optional[dict] = None
```

Accepting an arbitrary `dict` is a security risk (unexpected payloads, injection) and makes the API contract undefined. Define a dedicated typed model:

```python
class YieldContext(BaseModel):
    crop: Optional[str] = None
    predicted_yield: Optional[float] = None
    alerts: list[str] = []

class KrishiChatInput(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=64)
    query: str = Field(..., min_length=1, max_length=2000)
    yield_context: Optional[YieldContext] = None
    language: str = Field("auto", pattern=r"^(auto|en|hi)$")
```

---

## High Severity

### 3. No String Length Limits on Database Columns

`Column(String)` without a length works in SQLite but will cause issues in PostgreSQL/MySQL.

**Affected columns (all tables):**

- `User.name`, `User.email`, `User.hashed_password`, `User.role`, `User.city`, `User.device_id`, `User.profile_photo`, `User.cover_photo`
- `Field.name`, `Field.crop`
- `YieldRecord.crop`

**Fix:** Add explicit lengths:

```python
name = Column(String(100), nullable=False)
email = Column(String(255), unique=True, index=True, nullable=False)
hashed_password = Column(String(255), nullable=False)
role = Column(String(20), default="farmer")
```

---

## Medium Severity

### 4. No `updated_at` Column on Any Table

There is no way to audit when a record was last modified. Every table should have:

```python
updated_at = Column(
    DateTime(timezone=True),
    server_default=func.now(),
    onupdate=func.now()
)
```

---

### 5. No Cascade Deletes on Relationships

If a `User` is deleted, their `fields`, `sensor_logs`, and `yield_records` become orphaned rows.

**Fix:**

```python
# On the User model
fields = relationship("Field", back_populates="user", cascade="all, delete-orphan")
sensor_logs = relationship("SensorLog", back_populates="user", cascade="all, delete-orphan")
yields = relationship("YieldRecord", back_populates="user", cascade="all, delete-orphan")
```

---

### 6. Missing `from_attributes = True` on Output Schemas

These output schemas are missing the ORM config and will fail if created from SQLAlchemy objects:

- `YieldOut`
- `KrishiYieldOut`
- `FertilizerRecommendationOutput`
- `KrishiChatOut`

**Fix:** Add to each:

```python
class Config:
    from_attributes = True
```

Or use the Pydantic v2 style:

```python
model_config = ConfigDict(from_attributes=True)
```

---

### 7. No Error or Pagination Response Schemas

Production APIs need standardized response structures:

```python
class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None

class PaginatedResponse(BaseModel):
    items: list
    total: int
    page: int
    page_size: int
    has_next: bool
```

---

### 8. Missing Index on `SensorLog.timestamp`

`SensorLog.timestamp` will be queried by date range frequently but has no index. This will cause slow queries as data grows.

```python
timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
```

---

## Low Severity

### 9. `is_deleted` Uses `Integer` Instead of `Boolean`

**Current:**

```python
# Model
is_deleted = Column(Integer, default=0)

# Schema
is_deleted: int
```

**Fix:**

```python
# Model
from sqlalchemy import Boolean
is_deleted = Column(Boolean, default=False)

# Schema
is_deleted: bool
```

Also consider whether `is_deleted` should be exposed in `UserOut` at all — soft-deleted users should typically be filtered out before reaching the response.

---

### 10. Token Schema Lacks Expiry Information

**Current:**

```python
class Token(BaseModel):
    access_token: str
    token_type: str
```

Clients don't know when to refresh. Add:

```python
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds until expiry
```

---

## Summary

| #   | Issue                                                  | Severity     | Effort |
| --- | ------------------------------------------------------ | ------------ | ------ |
| 1   | No input validation (email, password, lengths, ranges) | **Critical** | Medium |
| 2   | Untyped `dict` in `KrishiChatInput`                    | **Critical** | Low    |
| 3   | No string length on DB columns                         | **High**     | Medium |
| 4   | No `updated_at` column                                 | **Medium**   | Low    |
| 5   | No cascade deletes                                     | **Medium**   | Low    |
| 6   | Missing `from_attributes` on output schemas            | **Medium**   | Low    |
| 7   | No error/pagination schemas                            | **Medium**   | Medium |
| 8   | Missing index on `SensorLog.timestamp`                 | **Medium**   | Low    |
| 9   | `is_deleted` as int instead of bool                    | **Low**      | Low    |
| 10  | Token schema lacks expiry                              | **Low**      | Low    |

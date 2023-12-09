from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, MetaData, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from fastapi.middleware.cors import CORSMiddleware
import socket


# Replace the following variables with your own database connection details
DATABASE_URL = "postgresql://kube:kube@postgres-service/milestone"

# Create a FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create a SQLAlchemy engine and database session
engine = create_engine(DATABASE_URL)
metadata = MetaData()

# Define a table
fullname = Table(
    "fullname",
    metadata,
    Column("id", Integer, primary_key=True, index=True),
    Column("name", String),
)

# Create the table if it doesn't exist
metadata.create_all(bind=engine)

# Create a SQLAlchemy model for the "users" table
Base = declarative_base()


class Fullname(Base):
    __tablename__ = "fullname"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)


# Define the SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency to get the database session


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Endpoint to get name


@app.get("/")
async def root():
    return {"name": "Ahmed Mahgoub"}

# Endpoint to get hostname


@app.get("/id")
async def read_name(db: Session = Depends(get_db)):
    hostname = socket.gethostname()
    return {"hostname": hostname}


# Endpoint to get name

@app.get("/name")
async def read_name(db: Session = Depends(get_db)):
    hostname = socket.gethostname()
    db_name = db.query(Fullname).first()
    if db_name is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"name": db_name.name, "hostname": hostname}

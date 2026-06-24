
-- ENTERPRISE SUPPORT ANALYTICS & INCIDENT INTELLIGENCE PLATFORM
-- Phase 1: Database Schema (MySQL)
-- Author: Hitakshi Kathiriya


-- Step 1: Create and select the database
CREATE DATABASE IF NOT EXISTS support_analytics;
USE support_analytics;


-- TABLE 1: customers
-- Stores enterprise client information

CREATE TABLE customers (
    customer_id       INT PRIMARY KEY AUTO_INCREMENT,
    customer_name     VARCHAR(100) NOT NULL,
    industry          VARCHAR(50),
    country           VARCHAR(50),
    subscription_plan VARCHAR(50)
);


-- TABLE 2: products
-- Stores product/software versions being supported

CREATE TABLE products (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(100) NOT NULL,
    release_version VARCHAR(20)
);


-- TABLE 3: support_engineers
-- Stores support team members

CREATE TABLE support_engineers (
    engineer_id   INT PRIMARY KEY AUTO_INCREMENT,
    engineer_name VARCHAR(100) NOT NULL,
    team          VARCHAR(50)
);


-- TABLE 4: tickets
-- Core fact table — 100,000 rows

CREATE TABLE tickets (
    ticket_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id      INT,
    product_id       INT,
    engineer_id      INT,
    priority         VARCHAR(20),        -- Critical, High, Medium, Low
    status           VARCHAR(20),        -- Open, In Progress, Closed
    created_date     DATE,
    resolved_date    DATE,
    sla_hours        INT,                -- Agreed SLA limit in hours
    resolution_hours INT,               -- Actual hours taken to resolve
    root_cause       VARCHAR(100),
    FOREIGN KEY (customer_id)  REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)   REFERENCES products(product_id),
    FOREIGN KEY (engineer_id)  REFERENCES support_engineers(engineer_id)
);


-- TABLE 5: customer_feedback
-- Post-resolution satisfaction ratings

CREATE TABLE customer_feedback (
    feedback_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id   INT,
    rating      INT CHECK (rating BETWEEN 1 AND 5),
    comments    TEXT,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id)
);


-- VERIFY: Check all tables were created

SHOW TABLES;

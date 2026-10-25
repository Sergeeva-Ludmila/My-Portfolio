CREATE TABLE Departments (
    department_id SERIAL PRIMARY KEY,
    department_type VARCHAR(50),
    department_name VARCHAR(200),
    parent_department_id INT REFERENCES Departments(department_id)
);

CREATE TABLE Positions (
    position_id SERIAL PRIMARY KEY,
    position_name VARCHAR(100),
    department_id INT REFERENCES Departments(department_id)
);

CREATE TABLE Branches (
    branch_id SERIAL PRIMARY KEY,
    address TEXT
);

CREATE TABLE Projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(200)
);

CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    hire_date DATE,
    salary NUMERIC(10,2),
    position_id INT REFERENCES Positions(position_id),
    branch_id INT REFERENCES Branches(branch_id),
    project_id INT REFERENCES Projects(project_id)
);

CREATE TABLE ProjectAssignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES Employees(employee_id),
    project_id INT REFERENCES Projects(project_id),
    start_date DATE,
    end_date DATE
);

CREATE TABLE DepartmentHierarchy (
    hierarchy_id SERIAL PRIMARY KEY,
    parent_department_id INT REFERENCES Departments(department_id),
    child_department_id INT REFERENCES Departments(department_id)
);

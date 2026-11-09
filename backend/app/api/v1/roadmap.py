import re
from typing import List, Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.models.user import User
from app.api.v1.auth import get_current_user, get_optional_user

router = APIRouter(prefix="/roadmap", tags=["Career Roadmap"])

class RoadmapTask(BaseModel):
    id: int
    title: str
    completed: bool = False
    resource_link: Optional[str] = None

class RoadmapPhase(BaseModel):
    id: int
    phase_number: int
    title: str
    duration: str
    status: str  # "completed", "in_progress", "upcoming"
    description: str
    tasks: List[RoadmapTask]

class RoadmapResponse(BaseModel):
    target_role: str
    experience_level: str
    overall_progress: int
    estimated_weeks: int = 8
    phases: List[RoadmapPhase]

class GenerateRoadmapRequest(BaseModel):
    target_role: str = "Full-Stack Developer"
    experience_level: str = "Entry-to-Mid Level"
    weekly_hours: int = 10

def generate_role_specific_roadmap(target_role: str, level: str, weekly_hours: int = 10) -> RoadmapResponse:
    role_lower = target_role.lower()
    level_lower = level.lower()
    is_senior = "senior" in level_lower
    is_intern = "intern" in level_lower or ("entry" in level_lower and "mid" not in level_lower)

    # Scale durations based on study hours
    if weekly_hours <= 7:
        total_weeks = 14
        w1_weeks, w2_weeks, w3_weeks, w4_weeks = "Weeks 1–4", "Weeks 5–8", "Weeks 9–11", "Weeks 12–14"
    elif weekly_hours <= 14:
        total_weeks = 10
        w1_weeks, w2_weeks, w3_weeks, w4_weeks = "Weeks 1–3", "Weeks 4–6", "Weeks 7–8", "Weeks 9–10"
    elif weekly_hours <= 24:
        total_weeks = 6
        w1_weeks, w2_weeks, w3_weeks, w4_weeks = "Weeks 1–2", "Weeks 3–4", "Week 5", "Week 6"
    else:
        total_weeks = 4
        w1_weeks, w2_weeks, w3_weeks, w4_weeks = "Week 1", "Week 2", "Week 3", "Week 4"

    # 1. Full-Stack Developer Focused (Default Role)
    if any(k in role_lower for k in ["full-stack", "full stack", "fullstack", "software engineer", "mern", "mean"]):
        if is_intern:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="HTML/CSS, JavaScript ES6+ & Node.js Basics",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Master fundamental web technologies, DOM manipulation, and basic server creation for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Master JavaScript ES6+ (Async/await, array methods, closures, modules)", completed=True),
                        RoadmapTask(id=102, title="Build responsive UI components using React 19 and Tailwind CSS", completed=False),
                        RoadmapTask(id=103, title="Create RESTful API endpoints with Express / Node.js and SQLite database", completed=False),
                        RoadmapTask(id=104, title="Set up Git branching, GitHub repository workflows, and Postman testing", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Full-Stack CRUD Portfolio Capstone",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build and deploy an end-to-end web application with authentication and persistent database storage.",
                    tasks=[
                        RoadmapTask(id=201, title="Scaffold full-stack project (React frontend + Node/Express backend + SQLite)", completed=False),
                        RoadmapTask(id=202, title="Implement user signup, login, password hashing (bcrypt), and JWT auth", completed=False),
                        RoadmapTask(id=203, title="Deploy frontend to Vercel and backend to Render with live public URLs", completed=False),
                        RoadmapTask(id=204, title="Write clean GitHub README with setup guides, screenshots, and architecture diagrams", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Junior Full-Stack ATS Resume & Portfolio",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Structure an entry-level resume showcasing deployed projects, GitHub links, and technical competencies.",
                    tasks=[
                        RoadmapTask(id=301, title="Highlight full-stack capstone and live deployed links prominently on resume", completed=False),
                        RoadmapTask(id=302, title="Audit resume against Junior Full-Stack job postings to exceed 85% ATS score", completed=False),
                        RoadmapTask(id=303, title="Pin top repositories with live demo links and interactive preview GIF walkthroughs", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Junior Full-Stack Coding & Web Fundamentals",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Prepare for junior coding challenges, HTTP concepts, database querying, and behavioral loops.",
                    tasks=[
                        RoadmapTask(id=401, title="Practice 25 fundamental coding challenges (Arrays, Strings, HashMaps, Recursion)", completed=False),
                        RoadmapTask(id=402, title="Review Web Fundamentals: HTTP status codes, CORS, cookies vs tokens, and SQL joins", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Junior Full-Stack Technical Interviews", completed=False),
                    ]
                ),
            ]
        elif is_senior:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Distributed Architecture, Micro-Frontends & High Concurrency",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Architect scalable web applications, event-driven backends, and decoupled micro-frontends for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Architect Micro-Frontends with Module Federation, Turborepo monorepos, and shared tokens", completed=True),
                        RoadmapTask(id=102, title="Design high-throughput event streaming with Kafka/RabbitMQ and Redis Cluster caching", completed=False),
                        RoadmapTask(id=103, title="Optimize Core Web Vitals (INP < 200ms, LCP < 2.5s) and database query execution plans", completed=False),
                        RoadmapTask(id=104, title="Implement multi-tenant PostgreSQL schemas with connection pooling and partitioning", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Enterprise Cloud Capstone, Kubernetes & Observability",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Architect and deploy an enterprise multi-tier cloud application with automated CI/CD and monitoring.",
                    tasks=[
                        RoadmapTask(id=201, title="Containerize microservices with multi-stage Dockerfiles and Helm Kubernetes charts", completed=False),
                        RoadmapTask(id=202, title="Implement OpenTelemetry distributed tracing, Prometheus metrics, and Grafana alerts", completed=False),
                        RoadmapTask(id=203, title="Automate zero-downtime blue-green CI/CD deployment pipelines with GitHub Actions", completed=False),
                        RoadmapTask(id=204, title="Establish automated test automation across unit, integration, and Playwright E2E suites", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Executive ATS Resume & Architectural Impact",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Position your resume for Senior/Staff/Lead Full-Stack roles with high-scale business metrics.",
                    tasks=[
                        RoadmapTask(id=301, title="Quantify scale metrics: 99.99% availability, 10M+ daily requests, and infrastructure cost cuts", completed=False),
                        RoadmapTask(id=302, title="Audit resume against Staff / Principal Full-Stack Engineer and Lead Architect roles", completed=False),
                        RoadmapTask(id=303, title="Publish Technical RFC / Architecture whitepaper detailing trade-offs and disaster recovery", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Large-Scale System Design & Engineering Leadership",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Master distributed systems, consensus protocols, database sharding, and engineering leadership.",
                    tasks=[
                        RoadmapTask(id=401, title="Master Staff System Design: Global CDNs, CAP theorem, database sharding, and consensus protocols", completed=False),
                        RoadmapTask(id=402, title="Prepare for engineering leadership loops: Architecture trade-offs, mentorship, and sprint governance", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Senior System Design and Engineering Leadership interviews", completed=False),
                    ]
                ),
            ]
        else:
            # Entry-to-Mid Level Full-Stack
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Modern React 19, TypeScript & Production APIs",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Solidify end-to-end full-stack development with strict TypeScript, modern React, and clean API design.",
                    tasks=[
                        RoadmapTask(id=101, title="Master strict TypeScript across React components, state stores, and backend models", completed=True),
                        RoadmapTask(id=102, title="Build production RESTful APIs with FastAPI or Express, input validation, and middleware", completed=False),
                        RoadmapTask(id=103, title="Design normalized PostgreSQL schemas with migrations, indexes, and connection pooling", completed=False),
                        RoadmapTask(id=104, title="Implement efficient client caching and server state with React Query / TanStack Query", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Production Full-Stack SaaS Capstone & Docker",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build and deploy a complete production-ready full-stack web application with authentication and containerization.",
                    tasks=[
                        RoadmapTask(id=201, title="Build full-stack app with Next.js App Router, SSR, and decoupled backend services", completed=False),
                        RoadmapTask(id=202, title="Implement secure JWT / OAuth2 authentication with role-based access control (RBAC)", completed=False),
                        RoadmapTask(id=203, title="Write production Dockerfile and Docker Compose multi-container setup (Web + API + DB)", completed=False),
                        RoadmapTask(id=204, title="Deploy to cloud (Render / AWS) with automated GitHub Actions CI/CD workflows", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="ATS Resume Optimization & Quantified Impact",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Highlight technical achievements, deployed links, and business value metrics on your resume.",
                    tasks=[
                        RoadmapTask(id=301, title="Quantify full-stack accomplishments: Page speedups, API throughput, and active user metrics", completed=False),
                        RoadmapTask(id=302, title="Tailor resume keywords to match Mid-Level Full-Stack and Software Engineer descriptions", completed=False),
                        RoadmapTask(id=303, title="Publish clean GitHub repository with architecture diagrams and API documentation", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Full-Stack System Design & Live Coding",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Prepare for full-stack system design, real-time coding rounds, and behavioral evaluations.",
                    tasks=[
                        RoadmapTask(id=401, title="Master Full-Stack System Design: Client-server architecture, caching layers, and database indexing", completed=False),
                        RoadmapTask(id=402, title="Practice live coding rounds: Data structures, asynchronous handlers, and UI state sync", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Technical Interviews with real-time feedback", completed=False),
                    ]
                ),
            ]

    # 2. Python / Backend Focused
    elif any(k in role_lower for k in ["python", "backend", "django", "fastapi", "flask"]):
        if is_intern:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Python Syntax, OOP & Core Data Structures",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Master Python 3 fundamentals, object-oriented programming, and essential data structures for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Master Python data types, list comprehensions, and dictionaries", completed=True),
                        RoadmapTask(id=102, title="Understand OOP concepts: Classes, inheritance, and magic methods", completed=False),
                        RoadmapTask(id=103, title="Practice Git workflow, branching, and virtual environments (venv)", completed=False),
                        RoadmapTask(id=104, title="Build first REST API using FastAPI with SQLite database", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Guided Portfolio Capstone & Pytest",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build an end-to-end CRUD project with automated testing to prove your abilities.",
                    tasks=[
                        RoadmapTask(id=201, title=f"Scaffold {target_role} portfolio project with clean modular structure", completed=False),
                        RoadmapTask(id=202, title="Write Pytest unit tests for all API endpoints and validation logic", completed=False),
                        RoadmapTask(id=203, title="Deploy API to Render / Railway with live Swagger documentation", completed=False),
                        RoadmapTask(id=204, title="Write beginner-friendly GitHub README with architecture diagrams", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Entry-Level ATS Resume & GitHub Showcase",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Structure an entry-level resume emphasizing coursework, personal projects, and core CS skills.",
                    tasks=[
                        RoadmapTask(id=301, title="Highlight personal projects and core CS competencies on resume", completed=False),
                        RoadmapTask(id=302, title="Audit resume against Junior Python postings to achieve 85+ ATS score", completed=False),
                        RoadmapTask(id=303, title="Pin 3 clean GitHub repositories with live links and demo GIFs", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Junior Coding Rounds & Core CS Prep",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Ace foundational algorithmic questions, basic SQL queries, and entry interview loops.",
                    tasks=[
                        RoadmapTask(id=401, title="Practice 25 LeetCode Easy problems (Arrays, Strings, HashMaps)", completed=False),
                        RoadmapTask(id=402, title="Review CS concepts: Big-O notation, HTTP status codes, and SQL joins", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Junior Technical Interviews", completed=False),
                    ]
                ),
            ]
        elif is_senior:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="High-Concurrency AsyncIO & Distributed Systems",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Master Python GIL internals, event loops, high-throughput microservices, and distributed state for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Analyze Python GIL limitations, AsyncIO event loop internals, and uvloop", completed=True),
                        RoadmapTask(id=102, title="Architect microservices with FastAPI, gRPC communication, and Pydantic v2", completed=False),
                        RoadmapTask(id=103, title="Optimize PostgreSQL with partition schemas, indexing, and PgBouncer pooling", completed=False),
                        RoadmapTask(id=104, title="Design distributed caching (Redis Cluster) and streaming queues with Kafka/Celery", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Enterprise Cloud Architecture & Observability",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Architect a resilient, multi-tenant enterprise backend with zero-downtime deployment.",
                    tasks=[
                        RoadmapTask(id=201, title="Implement distributed resilience: Circuit breakers, rate-limiting & idempotency", completed=False),
                        RoadmapTask(id=202, title="Write production Kubernetes manifests, Helm charts, and multi-stage Dockerfiles", completed=False),
                        RoadmapTask(id=203, title="Integrate OpenTelemetry distributed tracing, Prometheus metrics, and Grafana", completed=False),
                        RoadmapTask(id=204, title="Automate blue-green CI/CD deployment pipelines with zero downtime", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Senior/Staff ATS Resume & Business Impact",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Position resume for Senior/Staff roles with metrics on throughput, latency, and engineering leadership.",
                    tasks=[
                        RoadmapTask(id=301, title="Quantify architectural achievements: Throughput, 99.9% SLAs, and cloud cost cuts", completed=False),
                        RoadmapTask(id=302, title="Audit resume against Staff / Senior Python Backend recruiter benchmarks", completed=False),
                        RoadmapTask(id=303, title="Draft high-level System Architecture RFC document as a portfolio centerpiece", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Large-Scale System Design & Leadership Loops",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Master distributed system trade-offs, fault tolerance, and cross-functional engineering leadership.",
                    tasks=[
                        RoadmapTask(id=401, title="Master System Design: Sharding, CAP theorem, consensus, and event sourcing", completed=False),
                        RoadmapTask(id=402, title="Prepare for Staff-level trade-off debates, technical deep dives, and post-mortems", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Senior System Design and Leadership interviews", completed=False),
                    ]
                ),
            ]
        else:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Advanced Python & Production Backend APIs",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Deep-dive into async Python, API design, relational data modeling, and caching for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Master Python AsyncIO, type hints, generators, and context managers", completed=True),
                        RoadmapTask(id=102, title="Build scalable REST APIs using FastAPI with dependency injection and middleware", completed=False),
                        RoadmapTask(id=103, title="Optimize PostgreSQL queries, indexes, connection pooling, and migrations", completed=False),
                        RoadmapTask(id=104, title="Implement Redis caching and background task workers with Celery", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Microservices & Containerized Capstone",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Architect and containerize an enterprise-ready backend system for your portfolio.",
                    tasks=[
                        RoadmapTask(id=201, title=f"Scaffold {target_role} API service with automated Pytest test suite", completed=False),
                        RoadmapTask(id=202, title="Write production Dockerfile and Docker Compose multi-service setup", completed=False),
                        RoadmapTask(id=203, title="Integrate OAuth2 / JWT authentication with role-based permissions (RBAC)", completed=False),
                        RoadmapTask(id=204, title="Deploy service to cloud (AWS ECS / Render) with health-check monitoring", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="ATS Resume & Backend Profile Polish",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Tailor resume to pass backend ATS screening and showcase system design knowledge.",
                    tasks=[
                        RoadmapTask(id=301, title="Highlight throughput, latency reductions, and DB benchmarks on resume", completed=False),
                        RoadmapTask(id=302, title="Scan resume against live Python Backend job descriptions to hit 85+ match", completed=False),
                        RoadmapTask(id=303, title="Publish clean GitHub repo with architecture diagrams and Swagger documentation", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="System Design & Technical Interviews",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Master Python data structures, algorithms, and backend system design interview loops.",
                    tasks=[
                        RoadmapTask(id=401, title="Practice 15 core Backend coding challenges (Trees, Graphs, Hashing)", completed=False),
                        RoadmapTask(id=402, title="Review System Design: Load balancers, caching strategies, and database sharding", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Backend Technical Interviews", completed=False),
                    ]
                ),
            ]

    # 3. Frontend / React / Web Focused
    elif any(k in role_lower for k in ["frontend", "react", "vue", "angular", "ui", "web"]):
        if is_intern:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="HTML5, Modern CSS & JavaScript ES6+",
                    duration=w1_weeks,
                    status="in_progress",
                    description="Master modern semantic HTML, Flexbox/Grid layouts, and essential JavaScript programming.",
                    tasks=[
                        RoadmapTask(id=101, title="Master CSS Flexbox, Grid, responsive design, and CSS variables", completed=True),
                        RoadmapTask(id=102, title="Master JavaScript ES6+: Promises, async/await, closures, and DOM manipulation", completed=False),
                        RoadmapTask(id=103, title="Build first component-driven UI using React and Tailwind CSS", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Interactive React Portfolio Capstone",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build an interactive, fully responsive single-page application connected to a public API.",
                    tasks=[
                        RoadmapTask(id=201, title="Build React app with hooks (useState, useEffect, useMemo) and React Router", completed=False),
                        RoadmapTask(id=202, title="Handle API data fetching, loading spinners, and error boundaries", completed=False),
                        RoadmapTask(id=203, title="Deploy live website to Vercel / Netlify with custom domain", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Entry Frontend Resume & Web Portfolio",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Showcase deployed live web apps, GitHub source code, and responsive design skills.",
                    tasks=[
                        RoadmapTask(id=301, title="Feature live demo links and GitHub repositories prominently on resume", completed=False),
                        RoadmapTask(id=302, title="Run ATS check against Junior Frontend postings to achieve 85+ score", completed=False),
                        RoadmapTask(id=303, title="Test responsive UI on mobile, tablet, and desktop viewport sizes", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="JavaScript & UI Coding Rounds",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Crack JavaScript conceptual interviews, DOM manipulation exercises, and entry UI challenges.",
                    tasks=[
                        RoadmapTask(id=401, title="Practice JS coding questions: Debounce, throttle, deep clone, and event bubbling", completed=False),
                        RoadmapTask(id=402, title="Review Web Fundamentals: CORS, cookies, local storage, and rendering cycle", completed=False),
                        RoadmapTask(id=403, title="Complete 2 AI Mock Junior Frontend Interviews", completed=False),
                    ]
                ),
            ]
        elif is_senior:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Advanced TypeScript, Architecture & Web Vitals",
                    duration=w1_weeks,
                    status="in_progress",
                    description="Master strict TypeScript, compiler performance, micro-frontend architecture, and Core Web Vitals.",
                    tasks=[
                        RoadmapTask(id=101, title="Master advanced TypeScript: Conditional types, template literals, and AST transforms", completed=True),
                        RoadmapTask(id=102, title="Architect large-scale micro-frontends with Module Federation and monorepos (Turborepo)", completed=False),
                        RoadmapTask(id=103, title="Optimize Core Web Vitals (INP, LCP, CLS) to sub-second thresholds", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Enterprise Next.js SSR & Design System",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build an accessible, WCAG-compliant design system and enterprise full-stack Next.js app.",
                    tasks=[
                        RoadmapTask(id=201, title="Architect full-stack Next.js with Server Components, streaming, and Server Actions", completed=False),
                        RoadmapTask(id=202, title="Build accessible Design System with Storybook, Radix primitives, and tokens", completed=False),
                        RoadmapTask(id=203, title="Implement automated visual regression and E2E testing with Playwright", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Senior ATS Resume & Technical Leadership",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Emphasize frontend performance gains, user conversion impact, and design system governance.",
                    tasks=[
                        RoadmapTask(id=301, title="Quantify conversion rate improvements, bundle size reductions, and performance wins", completed=False),
                        RoadmapTask(id=302, title="Optimize resume for Staff / Principal Frontend and UI Architect roles", completed=False),
                        RoadmapTask(id=303, title="Publish open-source UI package or technical blog post on architecture patterns", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Frontend System Design & Architecture Loops",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Ace complex frontend architecture interviews, offline-first sync, and large-scale rendering.",
                    tasks=[
                        RoadmapTask(id=401, title="Master Frontend System Design (Google Docs collaborative editor, Infinite feed)", completed=False),
                        RoadmapTask(id=402, title="Prepare for cross-functional design system reviews and architecture defense", completed=False),
                        RoadmapTask(id=403, title="Conduct 2 AI Mock Senior Frontend Architecture interviews", completed=False),
                    ]
                ),
            ]
        else:
            phases = [
                RoadmapPhase(
                    id=1,
                    phase_number=1,
                    title="Modern Frontend Architecture & TypeScript",
                    duration=w1_weeks,
                    status="in_progress",
                    description=f"Master modern component architecture and state management for {target_role}.",
                    tasks=[
                        RoadmapTask(id=101, title="Deep dive into TypeScript strict typing, interfaces, and generics", completed=True),
                        RoadmapTask(id=102, title="Master React hooks, custom hooks, and performance profiling (React.memo/useCallback)", completed=False),
                        RoadmapTask(id=103, title="Implement global state management with Zustand or Redux Toolkit", completed=False),
                        RoadmapTask(id=104, title="Build pixel-perfect responsive layouts with Tailwind CSS and CSS Grid", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=2,
                    phase_number=2,
                    title="Production Web Application & SSR",
                    duration=w2_weeks,
                    status="upcoming",
                    description="Build a high-performance web app with Next.js and API integrations.",
                    tasks=[
                        RoadmapTask(id=201, title=f"Build modern {target_role} showcase app using Next.js App Router", completed=False),
                        RoadmapTask(id=202, title="Implement optimistic UI updates, debounced search, and infinite scrolling", completed=False),
                        RoadmapTask(id=203, title="Optimize Web Vitals (LCP, FID, CLS) to achieve a 95+ Lighthouse score", completed=False),
                        RoadmapTask(id=204, title="Deploy to Vercel/Netlify with CI/CD preview deployments", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=3,
                    phase_number=3,
                    title="Portfolio & ATS Resume Optimization",
                    duration=w3_weeks,
                    status="upcoming",
                    description="Showcase live interactive demo links and frontend metrics to recruiters.",
                    tasks=[
                        RoadmapTask(id=301, title="Curate live portfolio with embedded interactive demos and clean UI", completed=False),
                        RoadmapTask(id=302, title="Optimize resume bullet points focusing on user experience & page speed metrics", completed=False),
                        RoadmapTask(id=303, title="Pin top repositories with clean screenshots and animated GIF walkthroughs", completed=False),
                    ]
                ),
                RoadmapPhase(
                    id=4,
                    phase_number=4,
                    title="Frontend Coding & Live UI Challenges",
                    duration=w4_weeks,
                    status="upcoming",
                    description="Prepare for take-home projects and real-time coding interviews.",
                    tasks=[
                        RoadmapTask(id=401, title="Practice JavaScript polyfills, closures, event loop, and DOM manipulation", completed=False),
                        RoadmapTask(id=402, title="Complete 3 timed component building interview exercises", completed=False),
                        RoadmapTask(id=403, title="Pass AI-guided Mock Frontend Technical Interview", completed=False),
                    ]
                ),
            ]

    # 4. Mobile / Flutter / Android Focused
    elif any(k in role_lower for k in ["flutter", "mobile", "android", "ios", "react native"]):
        phases = [
            RoadmapPhase(
                id=1,
                phase_number=1,
                title="Flutter Architecture & Dart Deep-Dive",
                duration=w1_weeks,
                status="in_progress",
                description=f"Master reactive state management, asynchronous Dart, and clean mobile architecture for {target_role}.",
                tasks=[
                    RoadmapTask(id=101, title="Deep-dive into Dart Streams, isolates, and reactive programming", completed=True),
                    RoadmapTask(id=102, title="Implement scalable state management using BLoC or Riverpod", completed=False),
                    RoadmapTask(id=103, title="Build custom render objects, slivers, and complex animations", completed=False),
                ]
            ),
            RoadmapPhase(
                id=2,
                phase_number=2,
                title="Cross-Platform Production Capstone",
                duration=w2_weeks,
                status="upcoming",
                description="Build an offline-first, production-grade mobile app with secure local storage.",
                tasks=[
                    RoadmapTask(id=201, title="Architect offline sync using SQLite / Hive with REST API fallback", completed=False),
                    RoadmapTask(id=202, title="Implement push notifications, biometric auth, and deep linking", completed=False),
                    RoadmapTask(id=203, title="Write unit, widget, and integration tests to hit 80%+ coverage", completed=False),
                    RoadmapTask(id=204, title="Configure fastlane and automated release pipelines for Android & iOS", completed=False),
                ]
            ),
            RoadmapPhase(
                id=3,
                phase_number=3,
                title="ATS Resume & App Store Showcasing",
                duration=w3_weeks,
                status="upcoming",
                description="Present published apps, APK/TestFlight links, and mobile engineering achievements.",
                tasks=[
                    RoadmapTask(id=301, title="Feature published Google Play / App Store links prominently on resume", completed=False),
                    RoadmapTask(id=302, title="Scan resume against Flutter / Mobile Developer job descriptions", completed=False),
                    RoadmapTask(id=303, title="Record a 60-second video walkthrough of your mobile app capstone", completed=False),
                ]
            ),
            RoadmapPhase(
                id=4,
                phase_number=4,
                title="Mobile System Design & Technical Interviews",
                duration=w4_weeks,
                status="upcoming",
                description="Ace mobile-specific design questions, memory management, and platform channels.",
                tasks=[
                    RoadmapTask(id=401, title="Practice mobile system design (Offline sync, Image caching, Battery efficiency)", completed=False),
                    RoadmapTask(id=402, title="Master Dart/Flutter concurrency, memory profiling, and frame drop fixes", completed=False),
                    RoadmapTask(id=403, title="Complete 2 AI Mock Mobile Developer Technical Interviews", completed=False),
                ]
            ),
        ]

    # 5. Data Science / AI / Machine Learning
    elif any(k in role_lower for k in ["data", "ai", "machine learning", "ml", "deep learning", "llm", "rag"]):
        phases = [
            RoadmapPhase(
                id=1,
                phase_number=1,
                title="Data Pipelines & Modern Python Stack",
                duration=w1_weeks,
                status="in_progress",
                description=f"Master high-performance data processing, feature engineering, and analytics for {target_role}.",
                tasks=[
                    RoadmapTask(id=101, title="Master vectorized manipulation with Pandas, NumPy, and Polars", completed=True),
                    RoadmapTask(id=102, title="Write advanced SQL: Window functions, recursive queries, and query planning", completed=False),
                    RoadmapTask(id=103, title="Perform statistical EDA, hypothesis testing, and outlier handling", completed=False),
                    RoadmapTask(id=104, title="Build automated data validation and ingestion pipelines with Pydantic", completed=False),
                ]
            ),
            RoadmapPhase(
                id=2,
                phase_number=2,
                title="Applied ML, LLM / RAG & Production API",
                duration=w2_weeks,
                status="upcoming",
                description="Build an end-to-end Machine Learning model and Generative AI application with vector search.",
                tasks=[
                    RoadmapTask(id=201, title="Train and evaluate baseline ML models using Scikit-Learn / XGBoost", completed=False),
                    RoadmapTask(id=202, title="Build RAG system using LangChain/LlamaIndex with a Vector DB (Chroma/Pinecone)", completed=False),
                    RoadmapTask(id=203, title="Serve model predictions via FastAPI microservice containerized in Docker", completed=False),
                    RoadmapTask(id=204, title="Track experiments, hyperparameters, and artifacts using MLflow", completed=False),
                ]
            ),
            RoadmapPhase(
                id=3,
                phase_number=3,
                title="ATS Resume & AI Portfolio Showcase",
                duration=w3_weeks,
                status="upcoming",
                description="Present model metrics, dataset sizes, and business ROI clearly to technical recruiters.",
                tasks=[
                    RoadmapTask(id=301, title="Quantify model business impact (latency reduction, precision/recall, cost savings) on resume", completed=False),
                    RoadmapTask(id=302, title="Optimize resume for ATS keywords matching Data Scientist & ML Engineer postings", completed=False),
                    RoadmapTask(id=303, title="Publish interactive HuggingFace Space or Streamlit demo with clean GitHub repo", completed=False),
                ]
            ),
            RoadmapPhase(
                id=4,
                phase_number=4,
                title="ML System Design & Coding Interviews",
                duration=w4_weeks,
                status="upcoming",
                description="Prepare for data-structures coding, ML theory fundamentals, and large-scale ML system design.",
                tasks=[
                    RoadmapTask(id=401, title="Master ML System Design: Recommendation systems, search ranking, and feature stores", completed=False),
                    RoadmapTask(id=402, title="Review core ML concepts: Bias-variance tradeoff, regularization, and gradient descent", completed=False),
                    RoadmapTask(id=403, title="Complete 2 AI Mock Data Science & ML Technical Interviews", completed=False),
                ]
            ),
        ]

    # 6. DevOps / Cloud / SRE
    elif any(k in role_lower for k in ["devops", "cloud", "aws", "kubernetes", "sre", "docker", "terraform"]):
        phases = [
            RoadmapPhase(
                id=1,
                phase_number=1,
                title="Infrastructure as Code & Cloud Foundations",
                duration=w1_weeks,
                status="in_progress",
                description=f"Master Terraform, cloud networking, IAM policies, and Linux administration for {target_role}.",
                tasks=[
                    RoadmapTask(id=101, title="Write declarative multi-tier cloud infrastructure with Terraform / OpenTofu", completed=True),
                    RoadmapTask(id=102, title="Configure secure cloud networking: VPC peering, NAT gateways, and security groups", completed=False),
                    RoadmapTask(id=103, title="Automate Linux server hardening, SSH key rotation, and systemd services", completed=False),
                ]
            ),
            RoadmapPhase(
                id=2,
                phase_number=2,
                title="Kubernetes, CI/CD & Production GitOps",
                duration=w2_weeks,
                status="upcoming",
                description="Build an enterprise CI/CD pipeline and automated GitOps deployment on Kubernetes.",
                tasks=[
                    RoadmapTask(id=201, title="Deploy production Kubernetes cluster (EKS/GKE) with Helm and Ingress-NGINX", completed=False),
                    RoadmapTask(id=202, title="Build automated GitHub Actions CI/CD pipeline with Docker security scanning", completed=False),
                    RoadmapTask(id=203, title="Set up ArgoCD for automated declarative GitOps continuous synchronization", completed=False),
                    RoadmapTask(id=204, title="Deploy Prometheus, Grafana, and AlertManager for 24/7 cluster monitoring", completed=False),
                ]
            ),
            RoadmapPhase(
                id=3,
                phase_number=3,
                title="DevOps ATS Resume & Uptime Portfolio",
                duration=w3_weeks,
                status="upcoming",
                description="Showcase 99.99% uptime achievements, infrastructure cost optimizations, and automation metrics.",
                tasks=[
                    RoadmapTask(id=301, title="Quantify MTTR reductions, deployment frequency gains, and cloud bill savings on resume", completed=False),
                    RoadmapTask(id=302, title="Scan resume against Senior Cloud/DevOps listings to achieve 88+ ATS score", completed=False),
                    RoadmapTask(id=303, title="Publish GitHub repo with modular Terraform templates and CI/CD workflows", completed=False),
                ]
            ),
            RoadmapPhase(
                id=4,
                phase_number=4,
                title="Site Reliability System Design & Incident Loops",
                duration=w4_weeks,
                status="upcoming",
                description="Master disaster recovery, high-availability architecture, and incident management interviews.",
                tasks=[
                    RoadmapTask(id=401, title="Practice Infrastructure System Design: Multi-region failover, DDoS mitigation, DNS routing", completed=False),
                    RoadmapTask(id=402, title="Run simulated incident troubleshooting drills and write detailed post-mortems", completed=False),
                    RoadmapTask(id=403, title="Complete 2 AI Mock DevOps / SRE Technical Interviews", completed=False),
                ]
            ),
        ]

    # 7. Generic / Other Specialized Roles
    else:
        role_title = target_role.title()
        phases = [
            RoadmapPhase(
                id=1,
                phase_number=1,
                title=f"{role_title} Architecture & Core Stack",
                duration=w1_weeks,
                status="in_progress",
                description=f"Deep-dive into modern architectural patterns, industry tools, and core workflows for {role_title}.",
                tasks=[
                    RoadmapTask(id=101, title=f"Audit required tech stack & architecture standards for {role_title}", completed=True),
                    RoadmapTask(id=102, title=f"Configure professional developer environment, linters, and version control", completed=False),
                    RoadmapTask(id=103, title=f"Implement core domain models, schema designs, and baseline modules", completed=False),
                ]
            ),
            RoadmapPhase(
                id=2,
                phase_number=2,
                title=f"Production {role_title} Showcase Capstone",
                duration=w2_weeks,
                status="upcoming",
                description=f"Build and ship a production-grade capstone project demonstrating practical {role_title} capability.",
                tasks=[
                    RoadmapTask(id=201, title=f"Architect and build an end-to-end {role_title} capstone project", completed=False),
                    RoadmapTask(id=202, title="Implement automated test coverage, error handling, and security reviews", completed=False),
                    RoadmapTask(id=203, title="Deploy project to cloud environment with live demo and architecture README", completed=False),
                ]
            ),
            RoadmapPhase(
                id=3,
                phase_number=3,
                title=f"ATS Resume Alignment & {role_title} Branding",
                duration=w3_weeks,
                status="upcoming",
                description=f"Align resume keywords, GitHub repositories, and LinkedIn profile specifically for {role_title} recruiters.",
                tasks=[
                    RoadmapTask(id=301, title=f"Run ATS scanner against 3 live {role_title} job postings to achieve 85+ score", completed=False),
                    RoadmapTask(id=302, title="Rewrite resume bullet points emphasizing quantifiable metrics and business impact", completed=False),
                    RoadmapTask(id=303, title="Showcase live capstone links and architecture diagrams on LinkedIn & GitHub", completed=False),
                ]
            ),
            RoadmapPhase(
                id=4,
                phase_number=4,
                title=f"{role_title} Technical Interview Mastery",
                duration=w4_weeks,
                status="upcoming",
                description=f"Prepare for technical interviews, take-home exercises, and behavioral questions for {role_title}.",
                tasks=[
                    RoadmapTask(id=401, title=f"Review top 25 technical & conceptual interview questions for {role_title}", completed=False),
                    RoadmapTask(id=402, title="Complete 2 AI Mock Technical Interviews with targeted feedback", completed=False),
                    RoadmapTask(id=403, title="Submit 5 high-match job applications weekly and track recruiter outreach", completed=False),
                ]
            ),
        ]

    total_tasks = sum(len(p.tasks) for p in phases)
    completed_tasks = sum(sum(1 for t in p.tasks if t.completed) for p in phases)
    progress_pct = int((completed_tasks / total_tasks) * 100) if total_tasks > 0 else 0

    return RoadmapResponse(
        target_role=target_role,
        experience_level=level,
        overall_progress=progress_pct,
        estimated_weeks=total_weeks,
        phases=phases,
    )

@router.get("/current", response_model=RoadmapResponse)
def get_current_roadmap(current_user: Optional[User] = Depends(get_optional_user)):
    return generate_role_specific_roadmap(target_role="Full-Stack Developer", level="Entry-to-Mid Level")

@router.post("/generate", response_model=RoadmapResponse)
def generate_custom_roadmap(
    payload: GenerateRoadmapRequest,
    current_user: Optional[User] = Depends(get_optional_user)
):
    role = payload.target_role.strip() or "Full-Stack Developer"
    level = payload.experience_level.strip() or "Entry Level"
    hours = payload.weekly_hours if payload.weekly_hours > 0 else 10
    return generate_role_specific_roadmap(target_role=role, level=level, weekly_hours=hours)

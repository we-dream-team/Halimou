"""
Tests pour les endpoints d'employés et de paie
"""
import pytest
import pytest_asyncio


class TestEmployees:
    """Tests pour les opérations CRUD sur les employés"""
    
    @pytest.mark.asyncio

    
    async def test_create_employee(self, test_client, sample_employee_data):
        """Test de création d'un employé"""
        response = await test_client.post("/api/employees", json=sample_employee_data)
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == sample_employee_data["full_name"]
        assert data["role"] == sample_employee_data["role"]
        assert data["base_salary"] == sample_employee_data["base_salary"]
        assert data["is_active"] is True
        assert "id" in data
        assert "created_at" in data
    
    @pytest.mark.asyncio

    
    async def test_get_all_employees(self, test_client, sample_employee_data):
        """Test de récupération de tous les employés"""
        # Créer plusieurs employés
        for i in range(3):
            employee_data = {**sample_employee_data, "full_name": f"Employé {i}"}
            await test_client.post("/api/employees", json=employee_data)
        
        response = await test_client.get("/api/employees")
        assert response.status_code == 200
        employees = response.json()
        assert isinstance(employees, list)
        assert len(employees) == 3
    
    @pytest.mark.asyncio

    
    async def test_get_all_employees_include_inactive(self, test_client, sample_employee_data):
        """Test de récupération avec les employés inactifs"""
        # Créer un employé actif et un inactif
        active_response = await test_client.post("/api/employees", json=sample_employee_data)
        active = active_response.json()
        inactive_data = {**sample_employee_data, "full_name": "Inactif"}
        inactive_response = await test_client.post("/api/employees", json=inactive_data)
        inactive = inactive_response.json()
        
        # Désactiver le deuxième
        await test_client.put(f"/api/employees/{inactive['id']}", json={"is_active": False})
        
        # Récupérer sans inactifs
        response = await test_client.get("/api/employees")
        employees = response.json()
        employee_ids = [e["id"] for e in employees]
        assert active["id"] in employee_ids
        assert inactive["id"] not in employee_ids
        
        # Récupérer avec inactifs
        response = await test_client.get("/api/employees?include_inactive=true")
        employees = response.json()
        employee_ids = [e["id"] for e in employees]
        assert inactive["id"] in employee_ids
    
    @pytest.mark.asyncio

    
    async def test_update_employee(self, test_client, sample_employee_data):
        """Test de mise à jour d'un employé"""
        created_response = await test_client.post("/api/employees", json=sample_employee_data)
        created = created_response.json()
        employee_id = created["id"]
        
        update_data = {"base_salary": 3000.00, "role": "Chef pâtissier"}
        response = await test_client.put(f"/api/employees/{employee_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["base_salary"] == 3000.00
        assert data["role"] == "Chef pâtissier"
        assert data["full_name"] == sample_employee_data["full_name"]  # Inchangé
    
    @pytest.mark.asyncio

    
    async def test_delete_employee(self, test_client, sample_employee_data):
        """Test de suppression d'un employé"""
        created_response = await test_client.post("/api/employees", json=sample_employee_data)
        created = created_response.json()
        employee_id = created["id"]
        
        response = await test_client.delete(f"/api/employees/{employee_id}")
        assert response.status_code == 200
        
        # Vérifier que l'employé n'existe plus
        get_response = await test_client.get(f"/api/employees")
        employees = get_response.json()
        employee_ids = [e["id"] for e in employees]
        assert employee_id not in employee_ids


class TestPayrolls:
    """Tests pour les opérations CRUD sur les fiches de paie"""
    
    @pytest.mark.asyncio

    
    async def test_create_payroll(self, test_client, sample_employee_data, sample_payroll_data):
        """Test de création d'une fiche de paie"""
        # Créer d'abord un employé
        employee_response = await test_client.post("/api/employees", json=sample_employee_data)
        employee = employee_response.json()
        payroll_data = sample_payroll_data.copy()
        payroll_data["employee_id"] = employee["id"]
        
        response = await test_client.post("/api/payrolls", json=payroll_data)
        assert response.status_code == 200
        data = response.json()
        assert data["employee_id"] == employee["id"]
        assert data["period"] == payroll_data["period"]
        assert data["advances"] == payroll_data["advances"]
        assert "id" in data
    
    @pytest.mark.asyncio

    
    async def test_get_payrolls(self, test_client, sample_employee_data, sample_payroll_data):
        """Test de récupération des fiches de paie"""
        # Créer un employé et plusieurs fiches de paie
        employee_response = await test_client.post("/api/employees", json=sample_employee_data)
        employee = employee_response.json()
        
        periods = ["2024-01", "2024-02", "2024-03"]
        for period in periods:
            payroll_data = {**sample_payroll_data, "employee_id": employee["id"], "period": period}
            await test_client.post("/api/payrolls", json=payroll_data)
        
        response = await test_client.get("/api/payrolls")
        assert response.status_code == 200
        payrolls = response.json()
        assert isinstance(payrolls, list)
        assert len(payrolls) == 3
    
    @pytest.mark.asyncio

    
    async def test_get_payrolls_filtered(self, test_client, sample_employee_data, sample_payroll_data):
        """Test de récupération avec filtres"""
        # Créer deux employés
        employee1_response = await test_client.post("/api/employees", json=sample_employee_data)
        employee1 = employee1_response.json()
        employee2_data = {**sample_employee_data, "full_name": "Employé 2"}
        employee2_response = await test_client.post("/api/employees", json=employee2_data)
        employee2 = employee2_response.json()
        
        # Créer des fiches de paie
        payroll1_data = {**sample_payroll_data, "employee_id": employee1["id"], "period": "2024-01"}
        payroll2_data = {**sample_payroll_data, "employee_id": employee2["id"], "period": "2024-01"}
        await test_client.post("/api/payrolls", json=payroll1_data)
        await test_client.post("/api/payrolls", json=payroll2_data)
        
        # Filtrer par employé
        response = await test_client.get(f"/api/payrolls?employee_id={employee1['id']}")
        payrolls = response.json()
        assert len(payrolls) == 1
        assert payrolls[0]["employee_id"] == employee1["id"]
        
        # Filtrer par période
        response = await test_client.get("/api/payrolls?period=2024-01")
        payrolls = response.json()
        assert len(payrolls) == 2
    
    @pytest.mark.asyncio

    
    async def test_update_payroll(self, test_client, sample_employee_data, sample_payroll_data):
        """Test de mise à jour d'une fiche de paie"""
        employee_response = await test_client.post("/api/employees", json=sample_employee_data)
        employee = employee_response.json()
        payroll_data = {**sample_payroll_data, "employee_id": employee["id"]}
        payroll_response = await test_client.post("/api/payrolls", json=payroll_data)
        created = payroll_response.json()
        payroll_id = created["id"]
        
        update_data = {"advances": 750.00, "notes": "Avance mise à jour"}
        response = await test_client.put(f"/api/payrolls/{payroll_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["advances"] == 750.00
        assert data["notes"] == "Avance mise à jour"
    
    @pytest.mark.asyncio

    
    async def test_delete_payroll(self, test_client, sample_employee_data, sample_payroll_data):
        """Test de suppression d'une fiche de paie"""
        employee_response = await test_client.post("/api/employees", json=sample_employee_data)
        employee = employee_response.json()
        payroll_data = {**sample_payroll_data, "employee_id": employee["id"]}
        payroll_response = await test_client.post("/api/payrolls", json=payroll_data)
        created = payroll_response.json()
        payroll_id = created["id"]
        
        response = await test_client.delete(f"/api/payrolls/{payroll_id}")
        assert response.status_code == 200
        
        # Vérifier que la fiche n'existe plus
        get_response = await test_client.get("/api/payrolls")
        payrolls = get_response.json()
        payroll_ids = [p["id"] for p in payrolls]
        assert payroll_id not in payroll_ids


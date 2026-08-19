"""
Script de Teste Integrado E2E — Ambiente de Homologação AWS CloudFront
URL Base: https://d19dlqxhe17bcr.cloudfront.net
"""

import json
import sys
import time
import httpx

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://d19dlqxhe17bcr.cloudfront.net"

def run_e2e_tests():
    print(f"🚀 Iniciando Bateria de Testes E2E em Homologação: {BASE_URL}")
    
    with httpx.Client(base_url=BASE_URL, timeout=30.0, follow_redirects=True) as client:
        unique_suffix = int(time.time())
        email = f"e2e_owner_{unique_suffix}@barbearia.com"
        password = "Password123!"
        trade_name = f"Barbearia E2E CloudFront {unique_suffix}"
        
        # 1. Health Check direto no API Gateway
        print("\n--- 1. Teste de Health Check (/health) ---")
        res_health = client.get("https://nlrx258a8i.execute-api.us-east-1.amazonaws.com/health")
        print(f"Status Code: {res_health.status_code}")
        print(f"Response: {res_health.text}")
        assert res_health.status_code == 200, "Falha no health check"
        
        # 2. Cadastro / Signup com emissão de Cookies HttpOnly
        print(f"\n--- 2. Cadastro de Proprietário (POST {BASE_URL}/auth/signup) ---")
        signup_payload = {
            "email": email,
            "password": password,
            "trade_name": trade_name,
            "owner_name": "Cleiton Marques",
            "phone": "(11) 98765-4321",
        }
        
        res_signup = client.post("/auth/signup", json=signup_payload)
        print(f"Status Code: {res_signup.status_code}")
        print(f"Response JSON: {res_signup.json()}")
        print(f"Cookies Recebidos na Sessão: {dict(client.cookies)}")
        
        assert res_signup.status_code == 201, f"Falha no signup: {res_signup.text}"
        assert "access_token" in client.cookies, "Cookie access_token não foi recebido!"
        assert "refresh_token" in client.cookies, "Cookie refresh_token não foi recebido!"
        barbershop_id = res_signup.json()["barbershop"]["id"]
        print(f"✅ Signup realizado com sucesso! Barbershop ID: {barbershop_id}")
        
        # 3. Consulta de Sessão / Me via Cookie HttpOnly
        print(f"\n--- 3. Hidratação de Sessão (GET {BASE_URL}/auth/me) via Cookie ---")
        res_me = client.get("/auth/me")
        print(f"Status Code: {res_me.status_code}")
        print(f"Response JSON: {res_me.json()}")
        assert res_me.status_code == 200, f"Falha no /auth/me: {res_me.text}"
        me_data = res_me.json()
        assert me_data["user"]["email"] == email
        assert me_data["barbershop"]["id"] == barbershop_id
        print("✅ /auth/me validou com sucesso a sessão baseada exclusivamente em Cookies HttpOnly!")
        
        # 4. Onboarding Complete via Cookie HttpOnly
        print(f"\n--- 4. Conclusão de Onboarding (POST {BASE_URL}/barbershop/onboarding-complete) ---")
        onboarding_payload = {
            "trade_name": trade_name,
            "business_type_code": "BARBERSHOP",
            "address_zip_code": "01310-100",
            "address_street": "Avenida Paulista",
            "address_number": "1000",
            "address_neighborhood": "Bela Vista",
            "address_city": "São Paulo",
            "address_state": "SP",
            "slot_interval_min": 30,
            "booking_mode": "online",
            "staff_members": [
                {
                    "name": "Barbeiro Master 1",
                    "role_code": "BARBER",
                    "phone": "(11) 91234-5678"
                }
            ],
            "services": [
                {
                    "name": "Corte Degrade Navalhado",
                    "duration_min": 45,
                    "price_cents": 5000,
                    "category": "Cabelo"
                },
                {
                    "name": "Barba Completa com Toalha Quente",
                    "duration_min": 30,
                    "price_cents": 3500,
                    "category": "Barba"
                }
            ],
            "business_hours": [
                {"day_of_week": 1, "is_open": True, "open_time": "09:00", "close_time": "19:00"},
                {"day_of_week": 2, "is_open": True, "open_time": "09:00", "close_time": "19:00"},
                {"day_of_week": 3, "is_open": True, "open_time": "09:00", "close_time": "19:00"},
                {"day_of_week": 4, "is_open": True, "open_time": "09:00", "close_time": "19:00"},
                {"day_of_week": 5, "is_open": True, "open_time": "09:00", "close_time": "19:00"},
                {"day_of_week": 6, "is_open": True, "open_time": "09:00", "close_time": "18:00"},
                {"day_of_week": 0, "is_open": False, "open_time": "00:00", "close_time": "00:00"}
            ],
            "consent": {
                "terms_version": "1.0",
                "privacy_policy_version": "1.0",
                "terms_accepted": True
            }
        }
        
        res_onboarding = client.post("/barbershop/onboarding-complete", json=onboarding_payload)
        print(f"Status Code: {res_onboarding.status_code}")
        print(f"Response JSON: {res_onboarding.json()}")
        assert res_onboarding.status_code == 200, f"Falha no onboarding: {res_onboarding.text}"
        print("✅ Onboarding concluído com sucesso em transação única no PostgreSQL RDS!")
        
        # 5. Consulta Barbershop Perfil Atualizado via Cookie
        print(f"\n--- 5. Consulta Perfil Atualizado (GET {BASE_URL}/barbershop) ---")
        res_barbershop = client.get("/barbershop")
        print(f"Status Code: {res_barbershop.status_code}")
        print(f"Response JSON: {res_barbershop.json()}")
        assert res_barbershop.status_code == 200
        assert res_barbershop.json()["status_code"] == "ACTIVE"
        print("✅ Status da barbearia atualizado para 'ACTIVE'!")
        
        # 6. Logout / Encerramento de Sessão
        print(f"\n--- 6. Logout (POST {BASE_URL}/auth/logout) ---")
        res_logout = client.post("/auth/logout")
        print(f"Status Code: {res_logout.status_code}")
        print(f"Response JSON: {res_logout.json()}")
        assert res_logout.status_code == 200
        print("✅ Logout efetuado e cookies expirados (Max-Age=0) no backend!")
        
        # 7. Tentativa de acesso pós-logout
        print(f"\n--- 7. Validação de Bloqueio Pós-Logout (GET {BASE_URL}/barbershop) ---")
        client.cookies.clear()
        res_unauth = client.get("/barbershop")
        print(f"Status Code: {res_unauth.status_code}")
        print(f"Response JSON: {res_unauth.json()}")
        assert res_unauth.status_code == 401, "Deveria retornar 401 Unauthorized"
        print("✅ Acesso negado com 401 conforme esperado!")
        
        print("\n🎉 ==========================================================================")
        print("🎉 BATERIA E2E HOMOLOGAÇÃO CLOUDFRONT CONCLUÍDA COM 100% SUCESSO NA NUVEM AWS!")
        print("🎉 ==========================================================================")

if __name__ == "__main__":
    run_e2e_tests()

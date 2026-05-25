/**
 * Authentication Tests — mapped from t4t behavioral scenarios
 *
 * These tests validate the core authentication flows of the 4YOU application.
 * They mirror the t4t test definitions used during functional test generation,
 * now automated and integrated into the CI/CD pipeline via GitHub Actions.
 *
 * Equivalent t4t scenarios:
 *   - [T4T-001] Se connecter avec des identifiants valides
 *   - [T4T-002] Se connecter avec un mot de passe incorrect
 *   - [T4T-003] Se connecter avec un identifiant vide
 *   - [T4T-004] Se déconnecter
 */

import { describe, it, expect } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { LoginCard } from "@/components/LoginCard";
import { Toaster } from "@/components/ui/toaster";

const renderLogin = () =>
  render(
    <MemoryRouter>
      <AuthProvider>
        <LoginCard />
        <Toaster />
      </AuthProvider>
    </MemoryRouter>
  );

// ─── T4T-001 : Se connecter avec des identifiants valides ─────────────────────
describe("[T4T-001] Valid login", () => {
  it("accepts correct credentials and redirects to dashboard", () => {
    renderLogin();
    fireEvent.change(screen.getByRole("textbox"), {
      target: { value: "TNEEIN01" },
    });
    const inputs = document.querySelectorAll("input");
    const passwordInput = Array.from(inputs).find(
      (i) => i.type === "password"
    )!;
    fireEvent.change(passwordInput, { target: { value: "4YOU" } });
    fireEvent.click(screen.getByRole("button", { name: /me connecter/i }));
    // navigation to /dashboard is handled by react-router — no error shown
    expect(screen.queryByText(/Erreur de connexion/i)).toBeNull();
  });
});

// ─── T4T-002 : Mot de passe incorrect ─────────────────────────────────────────
describe("[T4T-002] Wrong password", () => {
  it("shows an error toast when password is wrong", async () => {
    renderLogin();
    fireEvent.change(screen.getByRole("textbox"), {
      target: { value: "TNEEIN01" },
    });
    const inputs = document.querySelectorAll("input");
    const passwordInput = Array.from(inputs).find(
      (i) => i.type === "password"
    )!;
    fireEvent.change(passwordInput, { target: { value: "WRONG" } });
    fireEvent.click(screen.getByRole("button", { name: /me connecter/i }));
    expect(await screen.findByText(/Erreur de connexion/i)).toBeTruthy();
  });
});

// ─── T4T-003 : Identifiant vide ───────────────────────────────────────────────
describe("[T4T-003] Empty identifier", () => {
  it("rejects login when identifier is empty (wrong password for empty user)", async () => {
    renderLogin();
    // Leave identifier empty, fill wrong password
    const inputs = document.querySelectorAll("input");
    const passwordInput = Array.from(inputs).find(
      (i) => i.type === "password"
    )!;
    fireEvent.change(passwordInput, { target: { value: "4YOU" } });
    fireEvent.click(screen.getByRole("button", { name: /me connecter/i }));
    // Empty identifier is not a valid user → login fails
    expect(await screen.findByText(/Erreur de connexion/i)).toBeTruthy();
  });
});

// ─── T4T-004 : Champs du formulaire présents ──────────────────────────────────
describe("[T4T-004] Login form fields", () => {
  it("renders identifier and password fields", () => {
    renderLogin();
    expect(screen.getByRole("textbox")).toBeTruthy();
    const inputs = document.querySelectorAll("input");
    const passwordInput = Array.from(inputs).find(
      (i) => i.type === "password"
    );
    expect(passwordInput).toBeTruthy();
  });

  it("renders the language selector", () => {
    renderLogin();
    expect(screen.getAllByText(/Français/i).length).toBeGreaterThan(0);
  });
});

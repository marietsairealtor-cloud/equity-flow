import WorkspacePicker from "./WorkspacePicker";
import CreateWorkspaceForm from "./CreateWorkspaceForm";
import LogoutButton from "../LogoutButton";

export default function WorkspacePage() {
  return (
    <main>
      <h1>Workspace</h1>

      <h2>Your memberships</h2>
      <WorkspacePicker />

      <h2>Create new</h2>
      <CreateWorkspaceForm />

      <LogoutButton />
    </main>
  );
}

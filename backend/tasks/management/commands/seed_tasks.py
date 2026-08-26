from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from tasks.models import Task

User = get_user_model()

TASKS = [
    {
        "title": "Review Q3 product roadmap",
        "description": "Go through the product roadmap for Q3 and align priorities with the team.",
        "completed": False,
        "due_date": 0,
    },
    {
        "title": "Send design handoff notes",
        "description": "Prepare and send the updated design specs to the frontend team.",
        "completed": False,
        "due_date": 0,
    },
    {
        "title": "Book customer interviews",
        "description": "Schedule calls with 5 key customers for user research.",
        "completed": False,
        "due_date": 2,
    },
    {
        "title": "Update billing details",
        "description": "Update the company billing information on the payment portal.",
        "completed": False,
        "due_date": 4,
    },
    {
        "title": "Write sprint retrospective notes",
        "description": "Document the highlights, lowlights, and action items from the last sprint.",
        "completed": True,
        "due_date": -1,
    },
    {
        "title": "Fix login page redirect bug",
        "description": "Users are being redirected to a 404 page after login. Investigate and fix.",
        "completed": False,
        "due_date": 1,
    },
    {
        "title": "Set up staging environment",
        "description": "Configure the staging server with Docker Compose and seed test data.",
        "completed": False,
        "due_date": 3,
    },
    {
        "title": "Prepare demo for stakeholders",
        "description": "Build a walkthrough of the new features for the Friday demo.",
        "completed": False,
        "due_date": 5,
    },
    {
        "title": "Close outstanding support tickets",
        "description": "Review and resolve the remaining 3 open support tickets.",
        "completed": True,
        "due_date": -2,
    },
    {
        "title": "Refactor task API serializers",
        "description": "Simplify the TaskSerializer and remove unused fields.",
        "completed": False,
        "due_date": 7,
    },
    {
        "title": "Write unit tests for auth flow",
        "description": "Cover register, login, token refresh, and logout scenarios.",
        "completed": False,
        "due_date": 6,
    },
    {
        "title": "Update project README",
        "description": "Add setup instructions and architecture diagram to the README.",
        "completed": True,
        "due_date": -3,
    },
]


class Command(BaseCommand):
    help = "Seed the database with sample tasks for an existing user."

    def add_arguments(self, parser):
        parser.add_argument(
            "--username",
            type=str,
            default="Sabs",
            help="Username to assign tasks to (default: Sabs)",
        )
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete all existing tasks before seeding",
        )

    def handle(self, *args, **options):
        username = options["username"]
        clear = options["clear"]

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            self.stderr.write(self.style.ERROR(f"User '{username}' does not exist."))
            return

        if clear:
            count, _ = Task.objects.filter(owner=user).delete()
            self.stdout.write(self.style.WARNING(f"Cleared {count} existing tasks."))

        now = timezone.now()
        created = 0
        for data in TASKS:
            due = now + timedelta(days=data["due_date"]) if data["due_date"] is not None else None
            Task.objects.create(
                owner=user,
                title=data["title"],
                description=data["description"],
                completed=data["completed"],
                due_date=due,
            )
            created += 1

        self.stdout.write(self.style.SUCCESS(f"Created {created} tasks for '{username}'."))

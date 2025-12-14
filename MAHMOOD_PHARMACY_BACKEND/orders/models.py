from django.db import models
from django.conf import settings

class Order(models.Model):
    STATUS_CHOICES = (
        ('Pending', 'Pending'),
        ('Shipped', 'Shipped'),
        ('Delivered', 'Delivered'),
        ('Cancelled', 'Cancelled'),
    )
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    shipping_address = models.TextField()
    contact_number = models.CharField(max_length=20)
    
    # Add other fields as necessary from your requirements

    def __str__(self):
        return f"Order #{self.id} - {self.user.email}"

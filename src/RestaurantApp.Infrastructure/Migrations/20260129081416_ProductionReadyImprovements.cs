using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestaurantApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ProductionReadyImprovements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Favorites_AspNetUsers_CustomerId1",
                table: "Favorites");

            migrationBuilder.DropColumn(
                name: "CustomerId",
                table: "Favorites");

            migrationBuilder.RenameIndex(
                name: "IX_OrderStatusHistories_OrderId",
                table: "OrderStatusHistories",
                newName: "IX_OrderStatusHistory_OrderId");

            migrationBuilder.RenameColumn(
                name: "CustomerId1",
                table: "Favorites",
                newName: "UserId");

            migrationBuilder.RenameIndex(
                name: "IX_Favorites_CustomerId1",
                table: "Favorites",
                newName: "IX_Favorites_UserId");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "UserAddresses",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "OrderStatusHistories",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Orders",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "OrderItems",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "OrderItemAddOns",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "NameEn",
                table: "Offers",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "NameAr",
                table: "Offers",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "Offers",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Offers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "MenuItems",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "MenuItemAddOns",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "MenuCategories",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Favorites",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Favorites",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "DeliveryZones",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Deliveries",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Branches",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "AspNetUsers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Token = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedByIp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    RevokedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RevokedByIp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ReplacedByToken = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    RevocationReason = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RefreshTokens", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_UserAddresses_IsDeleted",
                table: "UserAddresses",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_IsApproved",
                table: "Reviews",
                column: "IsApproved");

            migrationBuilder.CreateIndex(
                name: "IX_Restaurants_IsDeleted",
                table: "Restaurants",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_OrderStatusHistories_IsDeleted",
                table: "OrderStatusHistories",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Orders_IsDeleted",
                table: "Orders",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_IsDeleted",
                table: "OrderItems",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItemAddOns_IsDeleted",
                table: "OrderItemAddOns",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Offers_Code",
                table: "Offers",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Offers_EndDate",
                table: "Offers",
                column: "EndDate");

            migrationBuilder.CreateIndex(
                name: "IX_Offers_IsActive",
                table: "Offers",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Offers_IsDeleted",
                table: "Offers",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Offers_StartDate",
                table: "Offers",
                column: "StartDate");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItems_IsAvailable",
                table: "MenuItems",
                column: "IsAvailable");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItems_IsDeleted",
                table: "MenuItems",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItems_IsPopular",
                table: "MenuItems",
                column: "IsPopular");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItems_NameEn",
                table: "MenuItems",
                column: "NameEn");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItemAddOns_IsDeleted",
                table: "MenuItemAddOns",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_MenuCategories_IsDeleted",
                table: "MenuCategories",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_IsDeleted",
                table: "Favorites",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_DeliveryZones_IsDeleted",
                table: "DeliveryZones",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_IsDeleted",
                table: "Deliveries",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Branches_AcceptingOrders",
                table: "Branches",
                column: "AcceptingOrders");

            migrationBuilder.CreateIndex(
                name: "IX_Branches_IsActive",
                table: "Branches",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Branches_IsDeleted",
                table: "Branches",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_Token",
                table: "RefreshTokens",
                column: "Token");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_UserId",
                table: "RefreshTokens",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_AspNetUsers_UserId",
                table: "Favorites",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Favorites_AspNetUsers_UserId",
                table: "Favorites");

            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropIndex(
                name: "IX_UserAddresses_IsDeleted",
                table: "UserAddresses");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_IsApproved",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Restaurants_IsDeleted",
                table: "Restaurants");

            migrationBuilder.DropIndex(
                name: "IX_OrderStatusHistories_IsDeleted",
                table: "OrderStatusHistories");

            migrationBuilder.DropIndex(
                name: "IX_Orders_IsDeleted",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_OrderItems_IsDeleted",
                table: "OrderItems");

            migrationBuilder.DropIndex(
                name: "IX_OrderItemAddOns_IsDeleted",
                table: "OrderItemAddOns");

            migrationBuilder.DropIndex(
                name: "IX_Offers_Code",
                table: "Offers");

            migrationBuilder.DropIndex(
                name: "IX_Offers_EndDate",
                table: "Offers");

            migrationBuilder.DropIndex(
                name: "IX_Offers_IsActive",
                table: "Offers");

            migrationBuilder.DropIndex(
                name: "IX_Offers_IsDeleted",
                table: "Offers");

            migrationBuilder.DropIndex(
                name: "IX_Offers_StartDate",
                table: "Offers");

            migrationBuilder.DropIndex(
                name: "IX_MenuItems_IsAvailable",
                table: "MenuItems");

            migrationBuilder.DropIndex(
                name: "IX_MenuItems_IsDeleted",
                table: "MenuItems");

            migrationBuilder.DropIndex(
                name: "IX_MenuItems_IsPopular",
                table: "MenuItems");

            migrationBuilder.DropIndex(
                name: "IX_MenuItems_NameEn",
                table: "MenuItems");

            migrationBuilder.DropIndex(
                name: "IX_MenuItemAddOns_IsDeleted",
                table: "MenuItemAddOns");

            migrationBuilder.DropIndex(
                name: "IX_MenuCategories_IsDeleted",
                table: "MenuCategories");

            migrationBuilder.DropIndex(
                name: "IX_Favorites_IsDeleted",
                table: "Favorites");

            migrationBuilder.DropIndex(
                name: "IX_DeliveryZones_IsDeleted",
                table: "DeliveryZones");

            migrationBuilder.DropIndex(
                name: "IX_Deliveries_IsDeleted",
                table: "Deliveries");

            migrationBuilder.DropIndex(
                name: "IX_Branches_AcceptingOrders",
                table: "Branches");

            migrationBuilder.DropIndex(
                name: "IX_Branches_IsActive",
                table: "Branches");

            migrationBuilder.DropIndex(
                name: "IX_Branches_IsDeleted",
                table: "Branches");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "OrderStatusHistories");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "OrderItemAddOns");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Offers");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "MenuItems");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "MenuItemAddOns");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "MenuCategories");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Favorites");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Favorites");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "DeliveryZones");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "Branches");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "AspNetUsers");

            migrationBuilder.RenameIndex(
                name: "IX_OrderStatusHistory_OrderId",
                table: "OrderStatusHistories",
                newName: "IX_OrderStatusHistories_OrderId");

            migrationBuilder.RenameColumn(
                name: "UserId",
                table: "Favorites",
                newName: "CustomerId1");

            migrationBuilder.RenameIndex(
                name: "IX_Favorites_UserId",
                table: "Favorites",
                newName: "IX_Favorites_CustomerId1");

            migrationBuilder.AlterColumn<string>(
                name: "NameEn",
                table: "Offers",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(200)",
                oldMaxLength: 200);

            migrationBuilder.AlterColumn<string>(
                name: "NameAr",
                table: "Offers",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(200)",
                oldMaxLength: 200);

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "Offers",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AddColumn<string>(
                name: "CustomerId",
                table: "Favorites",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddForeignKey(
                name: "FK_Favorites_AspNetUsers_CustomerId1",
                table: "Favorites",
                column: "CustomerId1",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eKnjiga.Services.Migrations
{
    /// <inheritdoc />
    public partial class ChangedOrders : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "Orders",
                type: "nvarchar(300)",
                maxLength: 300,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StatusChangedAt",
                table: "Orders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StatusChangedByUserId",
                table: "Orders",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RevokedTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Token = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    RevokedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RevokedTokens", x => x.Id);
                });

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9373));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9375));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9377));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9378));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9379));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9381));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9382));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9383));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9385));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9386));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9412));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9416));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9417));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9419));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9420));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9422));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9423));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9425));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9426));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9428));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 11,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9430));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 12,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9431));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9344));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9346));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9346));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9347));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9348));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9348));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9219));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9220));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9221));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9222));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9223));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9224));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9225));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(9225));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(8955));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(8958));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(8959));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 17, 11, 35, 57, 181, DateTimeKind.Utc).AddTicks(8960));

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 2,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 3,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 4,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 5,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 6,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 7,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 8,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 9,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 10,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 11,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 12,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 13,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.UpdateData(
                table: "Orders",
                keyColumn: "Id",
                keyValue: 14,
                columns: new[] { "CancellationReason", "StatusChangedAt", "StatusChangedByUserId" },
                values: new object[] { null, null, null });

            migrationBuilder.CreateIndex(
                name: "IX_Orders_StatusChangedByUserId",
                table: "Orders",
                column: "StatusChangedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_StatusChangedByUserId",
                table: "Orders",
                column: "StatusChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.DropTable(
                name: "RevokedTokens");

            migrationBuilder.DropIndex(
                name: "IX_Orders_StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "StatusChangedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9611));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9618));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9620));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9623));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9625));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9627));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9629));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9631));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9633));

            migrationBuilder.UpdateData(
                table: "Authors",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9635));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9691));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9700));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9702));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9705));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9707));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9709));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9711));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9714));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 9,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9716));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 10,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9718));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 11,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9720));

            migrationBuilder.UpdateData(
                table: "Books",
                keyColumn: "Id",
                keyValue: 12,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9723));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9568));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9571));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9572));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9573));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9574));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9575));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9383));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9385));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9386));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9388));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 5,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9389));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 6,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9390));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 7,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9392));

            migrationBuilder.UpdateData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 8,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9393));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9030));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9032));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9033));

            migrationBuilder.UpdateData(
                table: "Countries",
                keyColumn: "Id",
                keyValue: 4,
                column: "CreatedAt",
                value: new DateTime(2026, 6, 14, 9, 39, 23, 99, DateTimeKind.Utc).AddTicks(9035));
        }
    }
}

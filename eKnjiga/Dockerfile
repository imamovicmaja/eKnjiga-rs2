FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["eKnjiga.WebAPI/eKnjiga.WebAPI.csproj", "eKnjiga.WebAPI/"]
RUN dotnet restore "eKnjiga.WebAPI/eKnjiga.WebAPI.csproj"
COPY . .
WORKDIR "/src/eKnjiga.WebAPI"
RUN dotnet build "eKnjiga.WebAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "eKnjiga.WebAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eKnjiga.WebAPI.dll"]
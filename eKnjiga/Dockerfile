FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

COPY ["eKnjiga.WebAPI/eKnjiga.WebAPI.csproj", "eKnjiga.WebAPI/"]
COPY ["eKnjiga.Worker/eKnjiga.Worker.csproj", "eKnjiga.Worker/"]

RUN dotnet restore "eKnjiga.WebAPI/eKnjiga.WebAPI.csproj"
RUN dotnet restore "eKnjiga.Worker/eKnjiga.Worker.csproj"

COPY . .

WORKDIR "/src/eKnjiga.WebAPI"
RUN dotnet publish "eKnjiga.WebAPI.csproj" -c Release -o /out/webapi /p:UseAppHost=false

WORKDIR "/src/eKnjiga.Worker"
RUN dotnet publish "eKnjiga.Worker.csproj" -c Release -o /out/worker /p:UseAppHost=false


FROM base AS webapi
WORKDIR /app
COPY --from=build /out/webapi ./
EXPOSE 80
ENTRYPOINT ["dotnet", "eKnjiga.WebAPI.dll"]

FROM base AS worker
WORKDIR /app
COPY --from=build /out/worker ./
ENTRYPOINT ["dotnet", "eKnjiga.Worker.dll"]

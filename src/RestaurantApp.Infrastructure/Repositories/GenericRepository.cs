using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Infrastructure.Data;
using System.Linq.Expressions;

namespace RestaurantApp.Infrastructure.Repositories;

public class GenericRepository<T> : IRepository<T> where T : class
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public GenericRepository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T?> GetByIdAsync(int id, bool asNoTracking = true)
    {
        if (asNoTracking)
        {
             // For GetById with NoTracking, we need to use Where or similar instead of Find
             var parameter = Expression.Parameter(typeof(T), "x");
             var property = Expression.Property(parameter, "Id");
             var idValue = Expression.Constant(id);
             var equal = Expression.Equal(property, idValue);
             var lambda = Expression.Lambda<Func<T, bool>>(equal, parameter);
             
             return await _dbSet.AsNoTracking().FirstOrDefaultAsync(lambda);
        }
        return await _dbSet.FindAsync(id);
    }

    public async Task<IEnumerable<T>> GetAllAsync(bool asNoTracking = true)
    {
        return asNoTracking ? await _dbSet.AsNoTracking().ToListAsync() : await _dbSet.ToListAsync();
    }

    public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate, bool asNoTracking = true)
    {
        return asNoTracking ? await _dbSet.AsNoTracking().Where(predicate).ToListAsync() : await _dbSet.Where(predicate).ToListAsync();
    }

    public async Task AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
    }

    public void Update(T entity)
    {
        _dbSet.Attach(entity);
        _context.Entry(entity).State = EntityState.Modified;
    }

    public void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }
}

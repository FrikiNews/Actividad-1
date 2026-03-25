// ── Contador animado para estadísticas ──
function animateCounter(el, target, suffix = '', duration = 1800) {
  let start = 0;
  const step = target / (duration / 16);
  const timer = setInterval(() => {
    start += step;
    if (start >= target) { start = target; clearInterval(timer); }
    el.textContent = Math.floor(start).toLocaleString('es-MX') + suffix;
  }, 16);
}

// Dispara contadores cuando la sección #stats entra en el viewport
const statsSection = document.getElementById('stats');
let statsAnimated = false;

const statsObserver = new IntersectionObserver((entries) => {
  if (entries[0].isIntersecting && !statsAnimated) {
    statsAnimated = true;
    animateCounter(document.getElementById('s1'), 450,  'M+');
    animateCounter(document.getElementById('s2'), 25,   '+');
    animateCounter(document.getElementById('s3'), 320,  '+');
    animateCounter(document.getElementById('s4'), 180,  '+');
  }
}, { threshold: 0.4 });

if (statsSection) statsObserver.observe(statsSection);

// ── Aparecer cards al hacer scroll ──
const cards = document.querySelectorAll('.card');
cards.forEach(c => { c.style.opacity = '0'; c.style.transform = 'translateY(30px)'; c.style.transition = 'opacity .5s ease, transform .5s ease'; });

const cardObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      cardObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });

cards.forEach(c => cardObserver.observe(c));

// ── Buscador ──
function handleSearch() {
  const query = document.getElementById('searchInput').value.trim().toLowerCase();
  if (!query) return;

  const routes = {
    'gasolina': 'Servicio de transporte de gasolinas disponible. Contáctanos para rutas y precios.',
    'diesel': 'Transporte de diésel con pipas certificadas NOM. Solicita cotización.',
    'crudo': 'Transporte de crudo en pipas herméticamente selladas con monitoreo GPS.',
    'gas': 'Manejo de gas LP y gas natural con unidades especializadas.',
  };

  let mensaje = `No encontramos resultados para "${query}". Contáctanos directamente para más información.`;
  for (const key in routes) {
    if (query.includes(key)) { mensaje = routes[key]; break; }
  }

  alert(mensaje);
}

// Permitir buscar con Enter
document.getElementById('searchInput').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') handleSearch();
});

// ── Formulario de contacto ──
function handleForm(e) {
  e.preventDefault();
  const name    = document.getElementById('fname').value.trim();
  const email   = document.getElementById('femail').value.trim();
  const company = document.getElementById('fcompany').value.trim();
  const msg     = document.getElementById('fmsg').value.trim();

  if (!name || !email) { alert('Por favor completa nombre y correo.'); return; }

  // Simulación de envío
  const btn = e.target.querySelector('button[type="submit"]');
  btn.textContent = 'Enviando...';
  btn.disabled = true;

  setTimeout(() => {
    btn.textContent = '¡Mensaje enviado!';
    btn.style.background = '#10b981';
    e.target.reset();
    setTimeout(() => {
      btn.textContent = 'Enviar mensaje';
      btn.style.background = '';
      btn.disabled = false;
    }, 3000);
  }, 1200);
}

// ── Navbar: cambiar fondo al hacer scroll ──
window.addEventListener('scroll', () => {
  const nav = document.querySelector('nav');
  if (window.scrollY > 60) {
    nav.style.background = 'rgba(10, 15, 38, 0.97)';
  } else {
    nav.style.background = 'rgba(10, 15, 38, 0.85)';
  }
});

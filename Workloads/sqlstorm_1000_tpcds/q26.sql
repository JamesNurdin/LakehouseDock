select
    s.s_state,
    d.d_year,
    sum(ss.ss_net_paid) as total_net_paid,
    sum(ss.ss_net_profit) as total_net_profit,
    sum(ss.ss_net_profit) / nullif(sum(ss.ss_net_paid), 0) * 100 as profit_margin_pct,
    avg(ss.ss_quantity) as avg_quantity,
    count(*) as sales_cnt
from store_sales ss
join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
join store s on ss.ss_store_sk = s.s_store_sk
join item i on ss.ss_item_sk = i.i_item_sk
join promotion p on ss.ss_promo_sk = p.p_promo_sk
where d.d_year = 1998
  and i.i_color = 'BLUE'
  and p.p_discount_active = 'Y'
  and ss.ss_quantity > 0
group by s.s_state, d.d_year
order by total_net_profit desc
limit 100

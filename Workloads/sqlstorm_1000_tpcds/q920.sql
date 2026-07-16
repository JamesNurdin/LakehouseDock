WITH
sales_by_date AS (
   SELECT
      d.d_date,
      c.cc_call_center_sk,
      c.cc_name,
      sum(cs.cs_net_paid) as total_catalog_net_paid,
      sum(cs.cs_net_profit) as total_catalog_net_profit,
      sum(ss.ss_net_paid) as total_store_net_paid,
      sum(ss.ss_net_profit) as total_store_net_profit,
      sum(ws.ws_net_paid) as total_web_net_paid,
      sum(ws.ws_net_profit) as total_web_net_profit
   FROM date_dim d
   LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center c ON c.cc_call_center_sk = cs.cs_call_center_sk
   LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
   GROUP BY d.d_date, c.cc_call_center_sk, c.cc_name
),
top_call_centers AS (
   SELECT
      d_date,
      cc_call_center_sk,
      cc_name,
      (coalesce(total_catalog_net_paid,0) + coalesce(total_store_net_paid,0) + coalesce(total_web_net_paid,0)) as total_net_paid,
      (coalesce(total_catalog_net_profit,0) + coalesce(total_store_net_profit,0) + coalesce(total_web_net_profit,0)) as total_net_profit,
      rank() over (partition by d_date order by (coalesce(total_catalog_net_paid,0) + coalesce(total_store_net_paid,0) + coalesce(total_web_net_paid,0)) desc) as net_paid_rank
   FROM sales_by_date
),
customer_spending AS (
   SELECT
      cs.cs_sold_date_sk as date_sk,
      cs.cs_bill_customer_sk as cust_sk,
      sum(cs.cs_net_paid) as catalog_spent
   FROM catalog_sales cs
   GROUP BY cs.cs_sold_date_sk, cs.cs_bill_customer_sk
),
store_customer_spending AS (
   SELECT
      ss.ss_sold_date_sk as date_sk,
      ss.ss_customer_sk as cust_sk,
      sum(ss.ss_net_paid) as store_spent
   FROM store_sales ss
   GROUP BY ss.ss_sold_date_sk, ss.ss_customer_sk
),
web_customer_spending AS (
   SELECT
      ws.ws_sold_date_sk as date_sk,
      ws.ws_bill_customer_sk as cust_sk,
      sum(ws.ws_net_paid) as web_spent
   FROM web_sales ws
   GROUP BY ws.ws_sold_date_sk, ws.ws_bill_customer_sk
),
combined_customer_spending AS (
   SELECT
      dsk.date_sk,
      dsk.cust_sk,
      coalesce(csp.catalog_spent,0) + coalesce(ssp.store_spent,0) + coalesce(wsp.web_spent,0) as total_spent
   FROM (
      SELECT distinct date_sk, cust_sk FROM (
         SELECT cs_sold_date_sk as date_sk, cs_bill_customer_sk as cust_sk FROM catalog_sales
         UNION ALL
         SELECT ss_sold_date_sk as date_sk, ss_customer_sk as cust_sk FROM store_sales
         UNION ALL
         SELECT ws_sold_date_sk as date_sk, ws_bill_customer_sk as cust_sk FROM web_sales
      ) u
   ) dsk
   LEFT JOIN customer_spending csp ON csp.date_sk = dsk.date_sk AND csp.cust_sk = dsk.cust_sk
   LEFT JOIN store_customer_spending ssp ON ssp.date_sk = dsk.date_sk AND ssp.cust_sk = dsk.cust_sk
   LEFT JOIN web_customer_spending wsp ON wsp.date_sk = dsk.date_sk AND wsp.cust_sk = dsk.cust_sk
),
top_customers_by_day AS (
   SELECT
      d_date,
      c_customer_id,
      full_name,
      total_spent,
      row_number() over (partition by d_date order by total_spent desc) as rn
   FROM (
      SELECT
         d.d_date,
         c.c_customer_id,
         concat(c.c_first_name, ' ', c.c_last_name) as full_name,
         sum(ccs.total_spent) as total_spent
      FROM combined_customer_spending ccs
      JOIN date_dim d ON d.d_date_sk = ccs.date_sk
      JOIN customer c ON c.c_customer_sk = ccs.cust_sk
      WHERE d.d_year = 2000
      GROUP BY d.d_date, c.c_customer_id, c.c_first_name, c.c_last_name
      HAVING sum(ccs.total_spent) > 0
   ) t
),
promo_effect AS (
   SELECT
      i.i_item_sk,
      p.p_promo_id,
      p.p_discount_active,
      sum(cs.cs_net_paid) as total_net_paid,
      sum(cs.cs_net_profit) as total_net_profit,
      avg(p.p_cost) as avg_promo_cost
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE p.p_discount_active = 'Y'
   GROUP BY i.i_item_sk, p.p_promo_id, p.p_discount_active
),
final AS (
   SELECT
      t.d_date,
      t.cc_name,
      t.total_net_paid,
      t.total_net_profit,
      t.net_paid_rank,
      coalesce(c.c_customer_id, 'UNKNOWN') as top_customer_id,
      coalesce(c.full_name, 'UNKNOWN') as top_customer_name,
      coalesce(c.total_spent, 0) as top_customer_spent,
      pe.p_promo_id,
      pe.total_net_paid as promo_net_paid,
      round(pe.total_net_profit / nullif(pe.total_net_paid,0), 4) as promo_profit_margin,
      case
         when pe.total_net_paid > 100000 then 'HIGH'
         when pe.total_net_paid > 50000 then 'MEDIUM'
         else 'LOW'
      end as promo_spend_category
   FROM top_call_centers t
   LEFT JOIN (
      SELECT d_date, c_customer_id, full_name, total_spent
      FROM top_customers_by_day
      WHERE rn = 1
   ) c ON c.d_date = t.d_date
   LEFT JOIN promo_effect pe ON pe.i_item_sk = (
      SELECT i_item_sk
      FROM item
      WHERE i_brand = 'Brand#45'
      ORDER BY i_current_price DESC
      LIMIT 1
   )
   WHERE t.net_paid_rank <= 10
)
SELECT *
FROM final
ORDER BY d_date, net_paid_rank

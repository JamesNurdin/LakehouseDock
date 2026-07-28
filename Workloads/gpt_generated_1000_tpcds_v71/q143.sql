/*
Goal: Identify the most profitable warehouse‑promotion‑year combinations for sales that occurred in 1999‑2000, filtering on high‑credit customers, active promotions, US‑west warehouses, and other business rules. The query joins all nine selected TPC‑DS tables using only the allowed surrogate‑key relationships, applies multiple predicates, uses DISTINCT in a CTE, aggregates with a ROLLUP, and ranks the results by profit within each year.
*/
WITH filtered AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        w.w_warehouse_name,
        w.w_gmt_offset,
        p.p_promo_name,
        p.p_discount_active,
        d.d_year,
        cd.cd_credit_rating,
        cd.cd_dep_college_count,
        inv.inv_quantity_on_hand,
        site.web_state,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site site
      ON site.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND w.w_gmt_offset = -5.00
      AND p.p_discount_active = 'Y'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_college_count >= 2
      AND cs.cs_list_price > 50
      AND ws.ws_quantity > 5
      AND inv.inv_quantity_on_hand > 0
      AND site.web_state = 'CA'
),
distinct_warehouses AS (
    SELECT DISTINCT w_warehouse_name
    FROM filtered
),
agg AS (
    SELECT
        w_warehouse_name,
        p_promo_name,
        d_year,
        SUM(cs_ext_sales_price) + SUM(ws_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) + SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM filtered
    GROUP BY ROLLUP (w_warehouse_name, p_promo_name, d_year)
)
SELECT
    agg.w_warehouse_name,
    agg.p_promo_name,
    agg.d_year,
    agg.total_sales,
    agg.total_profit,
    agg.distinct_orders,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_profit DESC) AS profit_rank
FROM agg
JOIN distinct_warehouses dw
  ON agg.w_warehouse_name = dw.w_warehouse_name
WHERE agg.w_warehouse_name IS NOT NULL
ORDER BY agg.d_year, profit_rank
LIMIT 100

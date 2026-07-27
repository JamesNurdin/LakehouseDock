/*
  Goal: Rank stores within each division by total net profit for 2002 sales to married customers under active promotions, including related call‑center and website information and inventory levels.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_division_id,
        cc.cc_name AS call_center_name,
        ws.web_name AS website_name,
        d_sales.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sales.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2002
      AND cd.cd_marital_status = 'M'
      AND p.p_discount_active = 'Y'
      AND cc.cc_zip = '28482'
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_division_id,
        cc.cc_name,
        ws.web_name,
        d_sales.d_year
)
SELECT
    s_store_sk,
    s_store_name,
    s_division_id,
    call_center_name,
    website_name,
    d_year,
    total_profit,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY s_division_id ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY s_division_id, profit_rank
LIMIT 100

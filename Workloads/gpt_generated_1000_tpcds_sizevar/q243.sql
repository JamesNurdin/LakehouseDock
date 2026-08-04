/* goal: Identify the top‑profit web orders, enriched with customer address and household demographics, that appear in both the address‑focused and site‑focused subsets, rank them per web site, categorize profit levels, and show total quantity ordered per order. */
WITH sales_addr_hdemo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ca.ca_zip,
        ca.ca_location_type,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ws.ws_web_site_sk
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_zip BETWEEN '10000' AND '50000'
      AND hd.hd_income_band_sk IN (12, 13, 14)
      AND hd.hd_buy_potential <> 'Unknown'
      AND ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
      AND ca.ca_location_type = 'single family'
),

sales_site AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_web_site_sk,
        site.web_name,
        site.web_rec_start_date,
        site.web_company_id
    FROM web_sales ws
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE site.web_rec_start_date >= DATE '2000-01-01'
      AND site.web_company_id IN (2, 3, 4)
      AND ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
      AND site.web_state = 'GA'
),

intersect_orders AS (
    SELECT ws_order_number FROM sales_addr_hdemo
    INTERSECT
    SELECT ws_order_number FROM sales_site
),

full_joined AS (
    SELECT
        sah.ws_order_number,
        sah.ca_zip,
        sah.hd_income_band_sk,
        sah.hd_buy_potential,
        ss.web_name,
        ss.web_rec_start_date,
        COALESCE(sah.ws_net_profit, ss.ws_net_profit) AS ws_net_profit,
        COALESCE(sah.ws_quantity, ss.ws_quantity) AS ws_quantity
    FROM sales_addr_hdemo sah
    FULL OUTER JOIN sales_site ss
        ON sah.ws_order_number = ss.ws_order_number
)
SELECT
    fj.ws_order_number,
    fj.ca_zip,
    fj.hd_income_band_sk,
    fj.hd_buy_potential,
    fj.web_name,
    fj.ws_net_profit,
    CASE
        WHEN fj.ws_net_profit > 1000 THEN 'High'
        WHEN fj.ws_net_profit > 100  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY fj.web_name ORDER BY fj.ws_net_profit DESC) AS profit_rank,
    qty_agg.total_qty_for_order,
    fj.ws_quantity
FROM full_joined fj
CROSS JOIN LATERAL (
    SELECT SUM(ws2.ws_quantity) AS total_qty_for_order
    FROM web_sales ws2
    WHERE ws2.ws_order_number = fj.ws_order_number
) AS qty_agg
WHERE fj.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
  AND fj.ws_quantity >= 10
  AND fj.web_rec_start_date < DATE '2005-01-01'
  AND fj.ca_zip NOT LIKE '9%'
  AND fj.hd_buy_potential LIKE '5%'
  AND fj.hd_income_band_sk <> 19
ORDER BY fj.ws_net_profit DESC
LIMIT 100

WITH agg AS (
    SELECT
        wsite.web_site_sk,
        wsite.web_name,
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE c.c_birth_country = 'MEXICO'
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 12
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY wsite.web_site_sk, wsite.web_name, sm.sm_ship_mode_id, sm.sm_type
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    agg.web_site_sk,
    agg.web_name,
    agg.sm_ship_mode_id,
    agg.sm_type,
    agg.distinct_customers,
    agg.total_net_profit,
    agg.total_sales,
    agg.avg_discount,
    agg.total_quantity,
    RANK() OVER (PARTITION BY agg.web_site_sk ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 50

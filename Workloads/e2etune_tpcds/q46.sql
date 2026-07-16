SELECT
    sm_ship_mode_id,
    sm_type,
    month,
    total_sales,
    total_discount,
    total_profit,
    avg_discount_rate,
    order_count,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        date_trunc('month', date_parse(cast(ws.ws_sold_date_sk AS varchar), '%Y%m%d')) AS month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_rate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND date_parse(cast(ws.ws_sold_date_sk AS varchar), '%Y%m%d')
          BETWEEN DATE '2020-01-01' AND DATE '2020-03-31'
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, date_trunc('month', date_parse(cast(ws.ws_sold_date_sk AS varchar), '%Y%m%d'))
    HAVING SUM(ws.ws_ext_sales_price) > 100000
) t
ORDER BY total_profit DESC
LIMIT 10

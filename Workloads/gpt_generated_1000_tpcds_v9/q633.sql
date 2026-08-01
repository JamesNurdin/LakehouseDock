WITH cat_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sale_date_sk,
        'Catalog' AS channel,
        p.p_promo_name AS promo_name,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_sold_date_sk) AS promo_seq,
        (SELECT SUM(cr.cr_return_amount)
         FROM catalog_returns cr
         WHERE cr.cr_returned_date_sk = cs.cs_sold_date_sk) AS total_return_amount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cs.cs_sold_date_sk, p.p_promo_name, sm.sm_ship_mode_id
),
web_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date_sk,
        'Web' AS channel,
        p.p_promo_name AS promo_name,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_sold_date_sk) AS promo_seq,
        (SELECT SUM(wr.wr_return_amt)
         FROM web_returns wr
         WHERE wr.wr_returned_date_sk = ws.ws_sold_date_sk) AS total_return_amount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ws.ws_sold_date_sk, p.p_promo_name, sm.sm_ship_mode_id
)
SELECT
    combined.*,
    SUM(total_net_paid) OVER (PARTITION BY channel ORDER BY sale_date_sk) AS cum_net_paid
FROM (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM web_sales
) AS combined
ORDER BY channel, sale_date_sk

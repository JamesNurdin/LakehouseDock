WITH
    store_sales_agg AS (
        SELECT
            p.p_promo_id,
            p.p_promo_name,
            d.d_year,
            d.d_moy,
            'store' AS channel,
            SUM(ss.ss_net_paid)      AS total_net_paid,
            SUM(ss.ss_net_profit)    AS total_net_profit,
            SUM(ss.ss_quantity)      AS total_quantity
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
    ),
    catalog_sales_agg AS (
        SELECT
            p.p_promo_id,
            p.p_promo_name,
            d.d_year,
            d.d_moy,
            'catalog' AS channel,
            SUM(cs.cs_net_paid)      AS total_net_paid,
            SUM(cs.cs_net_profit)    AS total_net_profit,
            SUM(cs.cs_quantity)      AS total_quantity
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
    ),
    web_sales_agg AS (
        SELECT
            p.p_promo_id,
            p.p_promo_name,
            d.d_year,
            d.d_moy,
            'web' AS channel,
            SUM(ws.ws_net_paid)      AS total_net_paid,
            SUM(ws.ws_net_profit)    AS total_net_profit,
            SUM(ws.ws_quantity)      AS total_quantity
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_moy
    ),
    combined AS (
        SELECT
            p_promo_id   AS promo_id,
            p_promo_name AS promo_name,
            d_year       AS year,
            d_moy        AS month,
            channel,
            total_net_paid,
            total_net_profit,
            total_quantity
        FROM store_sales_agg
        UNION ALL
        SELECT
            p_promo_id,
            p_promo_name,
            d_year,
            d_moy,
            channel,
            total_net_paid,
            total_net_profit,
            total_quantity
        FROM catalog_sales_agg
        UNION ALL
        SELECT
            p_promo_id,
            p_promo_name,
            d_year,
            d_moy,
            channel,
            total_net_paid,
            total_net_profit,
            total_quantity
        FROM web_sales_agg
    )
SELECT
    promo_id,
    promo_name,
    year,
    month,
    channel,
    total_net_paid,
    total_net_profit,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
ORDER BY year, month, profit_rank, promo_id

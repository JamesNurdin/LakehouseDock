WITH
    store_agg AS (
        SELECT
            p.p_promo_id,
            SUM(ss.ss_net_profit)                AS total_profit,
            COUNT(*)                             AS txn_cnt,
            AVG(ss.ss_ext_tax)                   AS avg_tax,
            SUM(val)                             AS sum_metric_values
        FROM (
            SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
        ) ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        CROSS JOIN UNNEST(ARRAY[ss.ss_quantity, CAST(ss.ss_ext_tax AS double)]) AS u(val)
        WHERE t.t_hour BETWEEN 9 AND 17
          AND cd.cd_credit_rating = 'Good'
        GROUP BY p.p_promo_id
        HAVING SUM(ss.ss_net_profit) > (
            SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2
        )
    ),
    web_agg AS (
        SELECT
            p.p_promo_id,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(*)              AS txn_cnt,
            AVG(ws.ws_ext_tax)    AS avg_tax
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE t.t_hour BETWEEN 9 AND 17
          AND cd.cd_credit_rating = 'Good'
        GROUP BY p.p_promo_id
        HAVING SUM(ws.ws_net_profit) > (
            SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2
        )
    )
SELECT
    s.p_promo_id,
    s.total_profit,
    s.txn_cnt,
    s.avg_tax
FROM   store_agg s
EXCEPT
SELECT
    w.p_promo_id,
    w.total_profit,
    w.txn_cnt,
    w.avg_tax
FROM   web_agg w
LIMIT 100

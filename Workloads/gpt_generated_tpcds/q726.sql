WITH
    sales_agg AS (
        SELECT
            s.s_store_id      AS store_id,
            d.d_year          AS year,
            d.d_moy           AS month,
            SUM(ss.ss_net_paid)          AS total_net_paid,
            SUM(ss.ss_quantity)          AS total_quantity,
            SUM(ss.ss_ext_discount_amt)  AS total_discount,
            SUM(ss.ss_net_profit)        AS total_profit
        FROM store_sales ss
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d
          ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p
          ON ss.ss_promo_sk = p.p_promo_sk
        WHERE p.p_discount_active = 'Y'
          AND d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year, d.d_moy
    ),
    returns_agg AS (
        SELECT
            s.s_store_id      AS store_id,
            d.d_year          AS year,
            d.d_moy           AS month,
            SUM(sr.sr_refunded_cash)    AS total_refunded_cash,
            SUM(sr.sr_return_quantity) AS total_return_quantity
        FROM store_returns sr
        JOIN store s
          ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d
          ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year, d.d_moy
    )
SELECT
    sa.store_id,
    sa.year,
    sa.month,
    sa.total_net_paid,
    COALESCE(ra.total_refunded_cash, 0)               AS total_refunded_cash,
    (sa.total_net_paid - COALESCE(ra.total_refunded_cash, 0)) AS net_sales,
    sa.total_quantity,
    COALESCE(ra.total_return_quantity, 0)            AS total_return_quantity,
    CASE WHEN sa.total_quantity > 0
         THEN COALESCE(ra.total_return_quantity, 0) * 1.0 / sa.total_quantity
         ELSE 0
    END                                              AS return_rate,
    CASE WHEN sa.total_quantity > 0
         THEN sa.total_discount * 1.0 / sa.total_quantity
         ELSE 0
    END                                              AS avg_discount_per_unit,
    sa.total_profit
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.store_id = ra.store_id
 AND sa.year     = ra.year
 AND sa.month    = ra.month
ORDER BY net_sales DESC
LIMIT 100

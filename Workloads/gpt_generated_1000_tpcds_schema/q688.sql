/*
  Goal: Compare net revenue from catalog sales with net loss from store returns by store and hour of day, using a UNION of two detailed sub‑queries, a LATERAL sub‑query to count promotions per item, a scalar sub‑query to fetch average quantity per item, an EXISTS filter, and a CUBE aggregation. The final result is ordered by total amount and paginated.
*/
WITH union_data AS (
    /* Catalog sales side – positive net paid */
    SELECT
        CAST(NULL AS varchar)               AS store_name,
        td.t_hour                           AS hour,
        CAST(
            cs.cs_net_paid
            - CAST(pl.promo_cnt AS decimal(7,2)) * 0.05
            - CAST(
                (SELECT AVG(cs2.cs_quantity)
                 FROM catalog_sales cs2
                 WHERE cs2.cs_item_sk = cs.cs_item_sk)
                AS decimal(7,2)
              ) * 0.01
        AS decimal(7,2))                    AS net_amount
    FROM catalog_sales cs
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS promo_cnt
        FROM promotion p2
        WHERE p2.p_item_sk = cs.cs_item_sk
    ) pl
    WHERE cs.cs_sales_price > 30
      AND i.i_brand IS NOT NULL
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs3
          WHERE cs3.cs_item_sk = cs.cs_item_sk
            AND cs3.cs_quantity > 5
      )

    UNION

    /* Store returns side – negative amount */
    SELECT
        s.s_store_name                      AS store_name,
        td.t_hour                           AS hour,
        CAST(-sr.sr_return_amt_inc_tax AS decimal(7,2)) AS net_amount
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = sr.sr_item_sk
            AND sr2.sr_return_amt_inc_tax > 100
      )
)
SELECT
    store_name,
    hour,
    SUM(net_amount) AS total_amount
FROM union_data
GROUP BY CUBE (store_name, hour)
ORDER BY total_amount DESC
OFFSET 0
LIMIT 100

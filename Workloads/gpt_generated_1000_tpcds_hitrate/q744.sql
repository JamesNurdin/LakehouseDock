/* goal: Analyze net paid sales by sold year and web market, ranking markets by total sales while demonstrating advanced SQL features (joins, filters, scalar subquery, EXISTS, GROUPING SETS, and window functions) */
WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk,
        cs.cs_ext_tax,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        w.web_mkt_id,
        w.web_mkt_desc,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN inventory i ON cs.cs_item_sk = i.inv_item_sk AND i.inv_date_sk = d_sold.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                                 -- filter 1 (realistic year)
      AND w.web_mkt_id = 3                                      -- filter 2 (specific market id)
      AND cs.cs_ext_tax > 100                                   -- filter 3 (tax amount)
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_item_sk = cs.cs_item_sk
            AND i2.inv_quantity_on_hand > 0
      )                                                         -- subquery EXISTS
      AND cs.cs_ext_tax > (
          SELECT MIN(cs2.cs_ext_tax)
          FROM catalog_sales cs2
      )                                                         -- scalar subquery comparison
)
SELECT
    sold_year,
    web_mkt_id,
    SUM(cs_net_paid)                         AS total_net_paid,
    AVG(cs_ext_discount_amt)                 AS avg_discount,
    COUNT(*)                                 AS sales_cnt,
    ROW_NUMBER() OVER (
        PARTITION BY web_mkt_id
        ORDER BY SUM(cs_net_paid) DESC
    )                                         AS rank_within_mkt,
    GROUPING(sold_year)                      AS g_sold_year,
    GROUPING(web_mkt_id)                     AS g_mkt_id
FROM filtered
GROUP BY GROUPING SETS (
    (sold_year, web_mkt_id),
    (web_mkt_id),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100

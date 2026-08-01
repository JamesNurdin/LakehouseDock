WITH agg AS (
    SELECT
        d_sr.d_year,
        cd.cd_gender,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_total,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM store_returns AS sr
    JOIN date_dim AS d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics AS cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory AS inv ON inv.inv_date_sk = d_sr.d_date_sk
    JOIN call_center AS cc ON cc.cc_open_date_sk = d_sr.d_date_sk
    JOIN catalog_page AS cp ON cp.cp_start_date_sk = d_sr.d_date_sk
    LEFT JOIN web_returns AS wr ON wr.wr_returned_date_sk = d_sr.d_date_sk
    JOIN web_site AS ws ON ws.web_open_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2001
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_employed_count >= 2
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'Promotion'
      AND ws.web_class = 'Online'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY d_sr.d_year, cd.cd_gender
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    d_year,
    cd_gender,
    SUM(store_return_total) AS total_store_return,
    SUM(web_return_total) AS total_web_return,
    AVG(avg_inventory_qty) AS avg_inventory_qty,
    AVG(SUM(store_return_total)) OVER (PARTITION BY d_year) AS avg_store_return_per_year,
    ROW_NUMBER() OVER (ORDER BY SUM(store_return_total) DESC) AS rank_by_store_return
FROM agg
GROUP BY GROUPING SETS ( (d_year, cd_gender), (d_year), () )
HAVING SUM(store_return_total) > 2000 OR d_year IS NULL
ORDER BY d_year NULLS LAST, cd_gender NULLS LAST
LIMIT 100

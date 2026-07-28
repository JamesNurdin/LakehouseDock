WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price)   AS total_sales,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        COUNT(*)                     AS sales_cnt
    FROM store_sales ss
    JOIN item i                     ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd   ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        hd.hd_dep_count      >= 2               -- predicate 1
        AND hd.hd_vehicle_count <= 3               -- predicate 2
        AND cd.cd_marital_status = 'M'            -- predicate 3
        AND ca.ca_state = 'CA'                    -- predicate 4
        AND i.i_category = 'Books'                -- predicate 5
    GROUP BY
        ss.ss_item_sk,
        i.i_category,
        i.i_product_name
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*)            AS return_cnt
    FROM catalog_returns cr
    JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        hd.hd_dep_count      >= 2
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
    GROUP BY cr.cr_item_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS total_web_loss,
        COUNT(*)            AS web_ret_cnt
    FROM web_returns wr
    JOIN item i                     ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd   ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
        hd.hd_dep_count      >= 2
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
    GROUP BY wr.wr_item_sk
)
SELECT
    sa.i_category,
    sa.ss_item_sk,
    sa.i_product_name,
    sa.total_sales,
    sa.total_net_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    COALESCE(wra.total_web_loss, 0)   AS total_web_loss,
    (sa.total_sales - COALESCE(ra.total_return_loss, 0) - COALESCE(wra.total_web_loss, 0)) AS net_sales_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY sa.i_category
        ORDER BY (sa.total_sales - COALESCE(ra.total_return_loss, 0) - COALESCE(wra.total_web_loss, 0)) DESC
    ) AS sales_rank
FROM sales_agg sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN returns_agg ra  ON sa.ss_item_sk = ra.cr_item_sk
LEFT JOIN web_ret_agg wra ON sa.ss_item_sk = wra.wr_item_sk
ORDER BY sa.i_category, sales_rank
LIMIT 100

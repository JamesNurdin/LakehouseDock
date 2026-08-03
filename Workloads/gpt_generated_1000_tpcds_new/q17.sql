WITH sales_agg AS (
    SELECT
        cp.cp_department,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_manager_id,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_product_name, 'ough')
      AND cp.cp_description LIKE '%fields%'
      AND sm.sm_carrier LIKE '%Express%'
      AND hd.hd_buy_potential LIKE 'HIGH%'
    GROUP BY
        cp.cp_department,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_manager_id
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_extract(i.i_product_name, '(ought)', 1) IS NOT NULL
      AND hd.hd_buy_potential LIKE 'HIGH%'
    GROUP BY
        i.i_item_sk,
        i.i_product_name
)
SELECT *
FROM (
    SELECT
        s.cp_department,
        s.i_product_name,
        s.i_brand,
        CONCAT(s.i_product_name, ' - ', s.i_brand) AS product_brand,
        s.total_sales_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_profit,
        ROW_NUMBER() OVER (
            PARTITION BY s.cp_department
            ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC
        ) AS rn
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.i_item_sk = r.i_item_sk
) t
WHERE t.rn <= 3
ORDER BY t.cp_department ASC, t.net_profit DESC
LIMIT 100

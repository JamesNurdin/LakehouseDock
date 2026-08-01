SELECT
    item_id,
    brand,
    category,
    total_net_paid,
    catalog_type,
    sales_year
FROM (
    SELECT
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        cp.cp_type AS catalog_type,
        d.d_year AS sales_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'monthly'
      AND d.d_year = 1998
      AND hd.hd_vehicle_count >= 2
    GROUP BY i.i_item_id, i.i_brand, i.i_category, cp.cp_type, d.d_year

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        cp.cp_type AS catalog_type,
        d.d_year AS sales_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'quarterly'
      AND d.d_year = 1999
      AND hd.hd_vehicle_count >= 2
    GROUP BY i.i_item_id, i.i_brand, i.i_category, cp.cp_type, d.d_year
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100

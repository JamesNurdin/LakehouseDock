WITH intersect_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'DHL'
    INTERSECT
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
)

SELECT
    agg.d_year,
    agg.i_item_id,
    agg.total_sales,
    DENSE_RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'Brand#22')
      AND cs.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)
      AND d.d_year = 1998
    GROUP BY d.d_year, i.i_item_id
) agg

UNION

SELECT
    agg.d_year,
    agg.i_item_id,
    agg.total_sales,
    DENSE_RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'Brand#22')
      AND cs.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)
      AND d.d_year = 1999
    GROUP BY d.d_year, i.i_item_id
) agg
ORDER BY d_year, total_sales DESC

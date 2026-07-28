WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_brand,
        i_brand_id,
        i_formulation,
        regexp_extract(i_formulation, '(\\d+)', 1) AS formulation_num,
        CASE
            WHEN regexp_like(i_formulation, '^\\d+') THEN 'starts_digit'
            ELSE 'no_digit_start'
        END AS formulation_prefix_flag
    FROM tpcds.item
    WHERE regexp_like(i_formulation, '\\d{3,}')
),
agg_sales AS (
    SELECT
        d.d_year,
        f.i_brand,
        f.i_brand_id,
        f.formulation_num,
        f.formulation_prefix_flag,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN filtered_items f
        ON ws.ws_item_sk = f.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'A%'
      AND d.d_year BETWEEN 2001 AND 2003
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = f.i_item_sk
              AND p.p_start_date_sk <= ws.ws_sold_date_sk
              AND p.p_end_date_sk >= ws.ws_sold_date_sk
        )
    GROUP BY GROUPING SETS (
        (d.d_year, f.i_brand, f.i_brand_id, f.formulation_num, f.formulation_prefix_flag),
        (d.d_year, f.i_brand, f.i_brand_id),
        (d.d_year)
    )
)
SELECT
    a.d_year,
    a.i_brand,
    a.i_brand_id,
    a.formulation_num,
    a.formulation_prefix_flag,
    a.total_sales,
    a.sales_cnt,
    a.avg_discount,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM agg_sales a
ORDER BY a.d_year, a.total_sales DESC
LIMIT 100

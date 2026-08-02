WITH base AS (
    SELECT
        cs.cs_quantity AS cs_quantity,
        cs.cs_sales_price AS cs_sales_price,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        cr.sr_return_amt AS sr_return_amt,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        dd.d_year AS d_year,
        dd.d_month_seq AS d_month_seq,
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        ib.ib_upper_bound AS ib_upper_bound,
        wp.wp_type AS wp_type
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN store_returns cr ON cr.sr_returned_date_sk = dd.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk AND cr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk AND cr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2002
      AND dd.d_month_seq BETWEEN 1200 AND 1220
      AND cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'S'
      AND ib.ib_upper_bound <= 120000
      AND inv.inv_quantity_on_hand > 100
),
agg_all AS (
    SELECT
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        ib_upper_bound,
        wp_type,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(inv_quantity_on_hand) AS total_inventory,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS transaction_count
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, cd_gender, cd_marital_status, ib_upper_bound, wp_type),
        (d_year, d_month_seq, cd_gender, cd_marital_status, ib_upper_bound),
        (d_year, d_month_seq, cd_gender, cd_marital_status),
        (d_year, d_month_seq, cd_gender),
        (d_year, d_month_seq),
        (d_year)
    )
),
agg_sub AS (
    SELECT
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        ib_upper_bound,
        wp_type,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(inv_quantity_on_hand) AS total_inventory,
        AVG(cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS transaction_count
    FROM base
    WHERE wp_type = 'product'
      AND ib_upper_bound = 120000
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, cd_gender, cd_marital_status, ib_upper_bound, wp_type),
        (d_year, d_month_seq, cd_gender, cd_marital_status, ib_upper_bound),
        (d_year, d_month_seq, cd_gender, cd_marital_status),
        (d_year, d_month_seq, cd_gender),
        (d_year, d_month_seq),
        (d_year)
    )
),
 diff AS (
    SELECT * FROM agg_all
    EXCEPT
    SELECT * FROM agg_sub
)
SELECT
    d_year,
    d_month_seq,
    cd_gender,
    cd_marital_status,
    ib_upper_bound,
    wp_type,
    total_quantity,
    total_sales,
    total_return_amt,
    total_inventory,
    avg_discount,
    transaction_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM diff
ORDER BY d_year, d_month_seq, sales_rank
LIMIT 100

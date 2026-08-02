WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_tax_percentage,
        cc.cc_rec_start_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_manufact_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_tax_percentage > 0.06
      AND i.i_manufact_id = 460
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND hd_bill.hd_buy_potential = '>10000'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_tax_percentage,
        cc.cc_rec_start_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_manufact_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    sa.cc_name AS call_center_name,
    sa.cc_tax_percentage,
    sa.i_product_name AS product_name,
    sa.i_manufact_id AS manufacturer_id,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    sa.total_net_paid,
    sa.total_discount,
    CASE WHEN sa.cc_tax_percentage > 0.08 THEN 'High Tax' ELSE 'Low Tax' END AS tax_category,
    RANK() OVER (ORDER BY sa.total_net_paid DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY sa.cc_call_center_sk ORDER BY sa.total_net_paid DESC) AS row_num_per_center,
    SUM(sa.total_net_paid) OVER (ORDER BY sa.total_net_paid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
    (SELECT SUM(wr2.wr_return_amt)
       FROM web_returns wr2
      WHERE wr2.wr_item_sk = sa.i_item_sk) AS total_return_amount
FROM sales_agg sa
LEFT JOIN (
    SELECT DISTINCT wr_item_sk
    FROM web_returns
) wr_exists
    ON sa.i_item_sk = wr_exists.wr_item_sk
ORDER BY sa.total_net_paid DESC
LIMIT 100

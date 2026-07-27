WITH base AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_type AS cp_type,
        i.i_brand_id AS i_brand_id,
        i.i_units AS i_units,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        wr.wr_return_amt AS wr_return_amt,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        cd_bill.cd_marital_status AS cd_marital_status,
        cd_refund.cd_gender AS refund_gender
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refund
        ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund
        ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    WHERE cp.cp_type = 'catalog'
      AND i.i_brand_id IN (2004001, 5003002)
      AND cd_bill.cd_marital_status = 'M'
      AND ib.ib_upper_bound >= 120000
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = wr.wr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
),
agg1 AS (
    SELECT
        cp_department,
        ib_upper_bound,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_returns
    FROM base
    GROUP BY cp_department, ib_upper_bound
),
overall_avg_profit AS (
    SELECT AVG(total_profit) AS avg_profit FROM agg1
)
SELECT
    a.cp_department,
    a.ib_upper_bound,
    a.total_sales,
    a.total_returns,
    (a.total_sales - a.total_returns) AS net_sales,
    a.total_profit,
    o.avg_profit
FROM agg1 a
CROSS JOIN overall_avg_profit o
WHERE a.total_sales > 100000
  AND (a.total_sales - a.total_returns) > 50000
  AND a.total_profit > o.avg_profit
ORDER BY net_sales DESC
LIMIT 100

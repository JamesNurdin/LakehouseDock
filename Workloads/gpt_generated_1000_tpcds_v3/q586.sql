WITH cs_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d_cs.d_year AS year,
        SUM(cs.cs_quantity) AS total_qty_sold,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F'
      AND i.i_current_price > 100
      AND d_cs.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_sk, i.i_product_name, d_cs.d_year
),
sr_agg AS (
    SELECT
        i.i_item_sk,
        d_sr.d_year AS year,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE s.s_state = 'CA'
      AND d_sr.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_sk, d_sr.d_year
),
wr_agg AS (
    SELECT
        i.i_item_sk,
        d_wr.d_year AS year,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE wp.wp_type = 'Content'
      AND d_wr.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_sk, d_wr.d_year
)
SELECT
    cs.i_item_sk,
    cs.i_product_name,
    cs.year,
    cs.total_qty_sold,
    cs.total_net_paid,
    cs.total_net_profit,
    COALESCE(sr.total_return_qty, 0) AS total_return_qty,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sr.total_net_loss, 0) AS total_store_net_loss,
    COALESCE(wr.total_web_return_qty, 0) AS total_web_return_qty,
    COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount,
    COALESCE(wr.total_web_net_loss, 0) AS total_web_net_loss,
    (cs.total_net_profit - COALESCE(sr.total_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) AS net_contribution,
    CASE
        WHEN (cs.total_net_profit - COALESCE(sr.total_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) > 10000 THEN 'High'
        WHEN (cs.total_net_profit - COALESCE(sr.total_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS contribution_category,
    ROW_NUMBER() OVER (PARTITION BY cs.year ORDER BY (cs.total_net_profit - COALESCE(sr.total_net_loss, 0) - COALESCE(wr.total_web_net_loss, 0)) DESC) AS rank_within_year
FROM cs_agg cs
LEFT JOIN sr_agg sr
    ON cs.i_item_sk = sr.i_item_sk AND cs.year = sr.year
LEFT JOIN wr_agg wr
    ON cs.i_item_sk = wr.i_item_sk AND cs.year = wr.year
ORDER BY cs.year, net_contribution DESC, rank_within_year
LIMIT 100

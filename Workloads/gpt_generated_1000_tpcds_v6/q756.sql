WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE p.p_response_target = 1
      AND d.d_year = 2001
      AND cc.cc_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        s_store_id,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss
    FROM base
    GROUP BY d_year, s_store_id
)
SELECT
    a.d_year,
    a.s_store_id,
    a.total_sales,
    a.total_net_profit,
    a.total_return_loss,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_channel_email = 'Y') AS max_email_promo_cost,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.d_year, profit_rank
LIMIT 100

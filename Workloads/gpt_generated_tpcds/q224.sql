WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_type,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_type,
        hd.hd_demo_sk,
        hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_type,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_type,
        hd.hd_demo_sk,
        hd.hd_buy_potential
)
SELECT
    s.cc_name,
    s.cp_type,
    s.hd_buy_potential,
    s.total_quantity_sold,
    s.total_sales_amount,
    s.total_net_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_sk = r.cc_call_center_sk
   AND s.cp_catalog_page_sk = r.cp_catalog_page_sk
   AND s.hd_demo_sk = r.hd_demo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100

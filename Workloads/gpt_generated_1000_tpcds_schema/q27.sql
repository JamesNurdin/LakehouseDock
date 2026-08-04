WITH store_part AS (
    SELECT
        ca.ca_state AS state,
        ss.ss_net_paid AS sales_amount,
        p.p_promo_name AS promo_name,
        CAST(NULL AS varchar) AS warehouse_name,
        'store' AS channel
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ca.ca_state IN ('CA', 'TX')
      AND cd.cd_gender = 'M'
      AND p.p_channel_radio = 'N'
),
web_part AS (
    SELECT
        ca_bill.ca_state AS state,
        ws.ws_net_paid AS sales_amount,
        p.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ca_bill.ca_state IN ('CA', 'TX')
      AND cd_bill.cd_gender = 'M'
      AND p.p_channel_radio = 'N'
      AND w.w_zip LIKE '5%'
)
SELECT
    state,
    sales_amount,
    promo_name,
    warehouse_name,
    channel,
    RANK() OVER (PARTITION BY state ORDER BY sales_amount DESC) AS state_rank
FROM (
    SELECT * FROM store_part
    UNION DISTINCT
    SELECT * FROM web_part
) AS combined
ORDER BY state_rank, sales_amount DESC
LIMIT 100

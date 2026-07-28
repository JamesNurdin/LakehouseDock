WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        r.r_reason_desc,
        ws.ws_list_price,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_amt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE cc.cc_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 10 AND 20
      AND r.r_reason_desc LIKE '%Customer%'
      AND ws.ws_list_price > 50
)
SELECT
    b.cc_name,
    b.cc_state,
    b.cd_gender,
    b.hd_income_band_sk,
    b.r_reason_desc,
    b.cs_net_paid,
    b.cs_net_profit,
    b.ws_list_price,
    b.ws_net_profit,
    b.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY b.cc_name ORDER BY b.cs_net_paid DESC) AS rn_net_paid,
    RANK() OVER (ORDER BY b.cs_net_paid + COALESCE(b.wr_return_amt, 0) DESC) AS rank_total,
    AVG(b.cs_net_paid) OVER (PARTITION BY b.cc_name) AS avg_net_paid_by_cc,
    (
        SELECT AVG(cs2.cs_net_paid)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_call_center_sk = b.cc_call_center_sk
    ) AS avg_net_paid_for_cc
FROM base b
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr2
    WHERE wr2.wr_order_number = b.cs_order_number
      AND wr2.wr_return_amt > 0
)
ORDER BY rank_total
LIMIT 100

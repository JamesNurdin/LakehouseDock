WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cc.cc_name,
        cc.cc_state AS cc_state,
        s.s_store_name,
        s.s_state AS s_state,
        w.web_name,
        w.web_state,
        i.inv_quantity_on_hand,
        cd.cd_gender
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.web_site w
        ON w.web_open_date_sk = d.d_date_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
)
SELECT
    d_date,
    d_year,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    cr_return_quantity,
    inv_quantity_on_hand,
    cd_gender,
    cc_name,
    cc_state,
    s_store_name,
    s_state,
    web_name,
    web_state,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY cs_net_paid DESC) AS rn_by_cc,
    RANK() OVER (PARTITION BY s_state ORDER BY cs_net_profit DESC) AS profit_rank_by_state
FROM base
WHERE d_year = 2001
  AND cs_quantity > 5
  AND inv_quantity_on_hand > 500
  AND cd_gender = 'M'
  AND cc_state = 'CA'
  AND s_state = 'CA'
UNION ALL
SELECT
    d_date,
    d_year,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    cr_return_quantity,
    inv_quantity_on_hand,
    cd_gender,
    cc_name,
    cc_state,
    s_store_name,
    s_state,
    web_name,
    web_state,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY cs_net_paid DESC) AS rn_by_cc,
    RANK() OVER (PARTITION BY s_state ORDER BY cs_net_profit DESC) AS profit_rank_by_state
FROM base
WHERE d_year = 2002
  AND cs_quantity > 10
  AND inv_quantity_on_hand <= 500
  AND cd_gender = 'F'
  AND cc_state = 'NY'
  AND s_state = 'NY'
ORDER BY d_year DESC, cs_net_paid DESC
LIMIT 100

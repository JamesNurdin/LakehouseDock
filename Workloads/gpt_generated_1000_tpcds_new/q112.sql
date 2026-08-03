WITH agg AS (
    SELECT
        wsite.web_name,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(i.i_current_price) AS avg_price,
        MIN(cr.cr_return_amount) AS min_return_amt,
        MAX(cr.cr_return_amount) AS max_return_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451060 AND 2451080
      AND i.i_current_price > 100
      AND sm.sm_type = 'AIR'
      AND wsite.web_state = 'CA'
      AND cd_bill.cd_gender = 'M'
      AND ca_bill.ca_state = 'TX'
      AND cr.cr_reversed_charge > 50
    GROUP BY GROUPING SETS (
        (wsite.web_name, i.i_category),
        (wsite.web_name),
        ()
    )
)
SELECT
    web_name,
    i_category,
    total_net_paid,
    order_cnt,
    avg_price,
    min_return_amt,
    max_return_amt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM agg
ORDER BY rn
LIMIT 100

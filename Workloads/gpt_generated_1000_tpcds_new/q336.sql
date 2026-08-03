WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
),
intersect_customers AS (
    SELECT cs.cs_bill_customer_sk AS c_sk FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_bill_customer_sk FROM web_sales ws
)
SELECT
    d_sales.d_year,
    i1.i_category,
    cp.cp_department,
    sm1.sm_carrier,
    w1.w_warehouse_name,
    c_bill.c_customer_id,
    cd_bill.cd_gender,
    ca_bill.ca_state,
    sales_agg.total_net_paid,
    returns_agg.total_return_amount,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d_sales.d_date_sk
    ) AS daily_return_sum,
    t.num AS catalog_number_or_page_number
FROM sales_agg
JOIN catalog_sales cs
    ON sales_agg.cs_item_sk = cs.cs_item_sk
   AND sales_agg.cs_sold_date_sk = cs.cs_sold_date_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN item i1
    ON cs.cs_item_sk = i1.i_item_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm1
    ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN warehouse w1
    ON cs.cs_warehouse_sk = w1.w_warehouse_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN returns_agg
    ON returns_agg.cr_item_sk = cs.cs_item_sk
   AND returns_agg.cr_returned_date_sk = cs.cs_sold_date_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_item_sk = cs.cs_item_sk
   AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
FULL OUTER JOIN web_sales ws
    ON ws.ws_item_sk = cs.cs_item_sk
   AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN item i2
    ON sr.sr_item_sk = i2.i_item_sk
JOIN customer c_ret
    ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN intersect_customers ic
    ON ic.c_sk = c_bill.c_customer_sk
CROSS JOIN UNNEST(ARRAY[cp.cp_catalog_page_number, cp.cp_catalog_number]) AS t(num)
WHERE d_sales.d_year = 2001
  AND sm1.sm_carrier = 'UPS'
GROUP BY
    d_sales.d_year,
    i1.i_category,
    cp.cp_department,
    sm1.sm_carrier,
    w1.w_warehouse_name,
    c_bill.c_customer_id,
    cd_bill.cd_gender,
    ca_bill.ca_state,
    sales_agg.total_net_paid,
    returns_agg.total_return_amount,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d_sales.d_date_sk
    ),
    t.num
ORDER BY d_sales.d_year DESC, sales_agg.total_net_paid DESC
OFFSET 0 LIMIT 100

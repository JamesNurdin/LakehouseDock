WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_brand,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_sold_time_sk AS time_sk,
        SUM(cs.cs_net_paid) AS total_sales_net,
        SUM(cs.cs_ext_sales_price) AS total_sales_ext_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_quantity) AS avg_quantity,
        CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca.ca_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_sold_time_sk
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category,
        s.s_store_name,
        r.r_reason_desc,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_return_quantity) > 50 THEN 'High Returns' ELSE 'Low Returns' END AS return_volume_category
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Did not like the color'
      AND hd.hd_vehicle_count > 0
      AND ca.ca_state = 'CA'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        s.s_store_name,
        r.r_reason_desc,
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_store_sk
)
SELECT
    s.year,
    s.month_seq,
    s.i_category,
    s.i_brand,
    s.total_sales_net,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.order_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    s.avg_quantity,
    s.volume_category,
    COALESCE(r.return_volume_category, 'No Returns') AS return_volume_category,
    RANK() OVER (PARTITION BY s.year ORDER BY s.total_sales_net DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.date_sk = r.date_sk
    AND s.item_sk = r.item_sk
ORDER BY s.total_sales_net DESC, s.year, s.month_seq
LIMIT 100

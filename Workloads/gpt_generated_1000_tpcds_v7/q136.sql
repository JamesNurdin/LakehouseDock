WITH sales_agg AS (
    SELECT
        c_bill.c_customer_sk,
        c_bill.c_customer_id,
        ca_bill.ca_city,
        d_sold.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MAX(p.p_promo_name) AS promo_name,
        MAX(w.w_warehouse_name) AS warehouse_name
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2020
      AND ca_bill.ca_city IN ('Maple Grove', 'Fairview')
      AND p.p_discount_active = 'Y'
    GROUP BY
        c_bill.c_customer_sk,
        c_bill.c_customer_id,
        ca_bill.ca_city,
        d_sold.d_year
),

returns_agg AS (
    SELECT
        c.c_customer_sk,
        d_ret.d_year,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        MAX(r_cr.r_reason_desc) AS catalog_return_reason,
        MAX(cp.cp_description) AS catalog_page_desc,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_return_loss,
        MAX(r_wr.r_reason_desc) AS web_return_reason
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr
        ON cr.cr_order_number = wr.wr_order_number
       AND cr.cr_item_sk = wr.wr_item_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d_ret.d_year = 2020
      AND cp.cp_department = 'Electronics'
    GROUP BY c.c_customer_sk, d_ret.d_year
)
SELECT
    s.c_customer_id,
    s.ca_city,
    s.d_year,
    s.total_sales,
    s.total_quantity,
    s.total_profit,
    COALESCE(r.catalog_return_amount, 0) AS catalog_return_amount,
    COALESCE(r.web_return_amount, 0) AS web_return_amount,
    (s.total_profit - COALESCE(r.catalog_return_loss, 0) - COALESCE(r.web_return_loss, 0)) AS adjusted_profit,
    s.promo_name,
    s.warehouse_name,
    r.catalog_page_desc,
    r.catalog_return_reason,
    r.web_return_reason,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.catalog_return_loss, 0) - COALESCE(r.web_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.c_customer_sk = r.c_customer_sk
   AND s.d_year = r.d_year
ORDER BY profit_rank
LIMIT 100

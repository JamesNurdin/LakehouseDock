WITH
    returns_data AS (
        SELECT
            cr.cr_returned_date_sk AS return_date_sk,
            cr.cr_return_amount AS return_amount,
            cr.cr_return_tax AS return_tax,
            cr.cr_net_loss AS net_loss,
            (cr.cr_return_amount - cr.cr_return_tax) AS net_return_amount,
            cr.cr_return_quantity AS return_quantity,
            c_ref.c_customer_sk AS customer_sk,
            c_ref.c_birth_month AS birth_month,
            t_ret.t_time AS return_time,
            t_ret.t_second AS return_second
        FROM catalog_returns cr
        JOIN time_dim t_ret
            ON cr.cr_returned_time_sk = t_ret.t_time_sk
        JOIN customer c_ref
            ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        WHERE cr.cr_return_amount > 50
          AND cr.cr_return_tax < 10
          AND cr.cr_net_loss > 0
          AND cr.cr_return_quantity >= 1
          AND c_ref.c_birth_month = 5
          AND t_ret.t_second BETWEEN 0 AND 30
    ),
    sales_data AS (
        SELECT
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_quantity AS sale_quantity,
            ws.ws_sales_price AS sale_price,
            ws.ws_net_profit AS net_profit,
            ws.ws_sales_price AS net_sale_amount,
            c_bill.c_customer_sk AS customer_sk,
            c_bill.c_preferred_cust_flag AS preferred_flag,
            t_sale.t_time AS sale_time,
            t_sale.t_second AS sale_second
        FROM web_sales ws
        JOIN time_dim t_sale
            ON ws.ws_sold_time_sk = t_sale.t_time_sk
        JOIN customer c_bill
            ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        WHERE ws.ws_quantity > 1
          AND ws.ws_net_profit > 0
          AND ws.ws_sales_price > 0
          AND ws.ws_ext_sales_price > 0
          AND c_bill.c_preferred_cust_flag = 'Y'
          AND t_sale.t_second BETWEEN 0 AND 30
          AND EXISTS (
              SELECT 1
              FROM promotion p
              WHERE ws.ws_promo_sk = p.p_promo_sk
                AND p.p_discount_active = 'Y'
                AND p.p_channel_email = 'Y'
          )
    ),
    combined AS (
        SELECT
            'return' AS record_type,
            return_date_sk AS date_sk,
            net_return_amount AS net_amount,
            net_loss,
            customer_sk,
            birth_month,
            return_time AS event_time,
            return_second AS event_second,
            return_quantity,
            CAST(NULL AS integer) AS sale_quantity,
            CAST(NULL AS decimal(7,2)) AS net_profit,
            ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY net_return_amount DESC) AS rn,
            SUM(net_return_amount) OVER (PARTITION BY customer_sk ORDER BY return_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_total
        FROM returns_data
        UNION ALL
        SELECT
            'sale' AS record_type,
            sold_date_sk AS date_sk,
            net_sale_amount AS net_amount,
            CAST(NULL AS decimal(7,2)) AS net_loss,
            customer_sk,
            CAST(NULL AS integer) AS birth_month,
            sale_time AS event_time,
            sale_second AS event_second,
            CAST(NULL AS integer) AS return_quantity,
            sale_quantity,
            net_profit,
            ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY net_sale_amount DESC) AS rn,
            SUM(net_sale_amount) OVER (PARTITION BY customer_sk ORDER BY sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_total
        FROM sales_data
    )
SELECT
    record_type,
    date_sk,
    net_amount,
    net_loss,
    customer_sk,
    birth_month,
    event_time,
    event_second,
    return_quantity,
    sale_quantity,
    net_profit,
    rn,
    moving_total
FROM combined
WHERE rn <= 5
ORDER BY record_type, rn
LIMIT 100

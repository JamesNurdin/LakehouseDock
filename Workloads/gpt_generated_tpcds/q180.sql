WITH sales_returns AS (
    SELECT
        s.s_store_name AS store_name,
        d_sales.d_year AS sales_year,
        d_sales.d_moy AS sales_month,
        i.i_category AS item_category,
        ss.ss_quantity AS sales_quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS sales_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS return_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d_sales.d_date BETWEEN DATE '2002-01-01' AND DATE '2003-12-31'
      AND p.p_discount_active = 'Y'
)
SELECT
    store_name,
    sales_year,
    sales_month,
    item_category,
    SUM(sales_quantity) AS total_quantity_sold,
    SUM(sales_amount) AS total_sales_amount,
    SUM(sales_profit) AS total_sales_profit,
    SUM(discount_amount) AS total_discount_amount,
    SUM(COALESCE(return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(return_loss, 0)) AS total_return_loss,
    (SUM(sales_profit) - SUM(COALESCE(return_loss, 0))) AS net_profit_after_returns
FROM sales_returns
GROUP BY store_name, sales_year, sales_month, item_category
ORDER BY sales_year, sales_month, total_sales_amount DESC
LIMIT 200

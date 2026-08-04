WITH sales_filtered AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_item_sk AS item_sk,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_list_price AS ext_list_price,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    WHERE ss.ss_ext_list_price > 1000
      AND ss.ss_customer_sk IN (
          SELECT c.c_customer_sk
          FROM customer c
          WHERE c.c_preferred_cust_flag = 'Y'
      )
)

SELECT *
FROM (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        s.ext_sales_price,
        s.ext_list_price,
        s.net_paid,
        CASE WHEN sr.sr_return_amt IS NULL THEN CAST(0.00 AS DECIMAL(7,2)) ELSE sr.sr_return_amt END AS return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY s.net_paid DESC) AS rn,
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_customer_sk = c.c_customer_sk) AS total_customer_return
    FROM sales_filtered s
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON s.hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = s.ticket_number
       AND sr.sr_item_sk = s.item_sk
    WHERE sr.sr_store_credit > 10
      AND hd.hd_buy_potential LIKE '%1000%'
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential,
             s.ext_sales_price, s.ext_list_price, s.net_paid,
             sr.sr_return_amt, c.c_customer_sk
    HAVING SUM(sr.sr_return_amt) > 100

    UNION

    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        s.ext_sales_price,
        s.ext_list_price,
        s.net_paid,
        CAST(0.00 AS DECIMAL(7,2)) AS return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY s.net_paid DESC) AS rn,
        (SELECT SUM(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_customer_sk = c.c_customer_sk) AS total_customer_return
    FROM sales_filtered s
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON s.hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = s.ticket_number
       AND sr.sr_item_sk = s.item_sk
    WHERE sr.sr_ticket_number IS NULL
      AND hd.hd_buy_potential = 'Unknown'
      AND c.c_birth_year = 1985
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential,
             s.ext_sales_price, s.ext_list_price, s.net_paid,
             c.c_customer_sk
) AS combined
ORDER BY total_customer_return DESC
LIMIT 100

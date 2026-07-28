/*
Goal: Identify high‑value customers (first name starting with "A" and login containing "shop") whose Gmail address matches a pattern, and who have a last name containing "Smith". The query combines store and web sales, extracts the email domain with regexp_extract, builds full names via concatenation, and aggregates total profit per customer demographic profile.
*/
WITH sales_union AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ss.ss_net_profit AS profit,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        c.c_login
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '^.+@gmail\\.com$')
      AND substr(c.c_first_name, 1, 1) = 'A'
      AND c.c_login LIKE '%shop%'

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ws.ws_net_profit AS profit,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        c.c_login
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '^.+@gmail\\.com$')
      AND substr(c.c_first_name, 1, 1) = 'A'
      AND c.c_login LIKE '%shop%'
)
SELECT
    full_name,
    cd_gender,
    hd_buy_potential,
    sum(profit) AS total_profit,
    count(DISTINCT c_customer_id) AS distinct_customers
FROM sales_union
WHERE full_name LIKE '%Smith%'
GROUP BY full_name, cd_gender, hd_buy_potential
ORDER BY total_profit DESC
LIMIT 100

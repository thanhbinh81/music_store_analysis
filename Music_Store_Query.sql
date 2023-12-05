---Question Set 1 - Easy 

/* Q1: Who is the senior most employee based on job title? */

select top(1) title, last_name, first_name
from employee
order by levels DESC

/* Q2: Which countries have the most Invoices? */

select top(1) billing_country, count(*) as number_of_invoices
from invoice
group by billing_country
order by number_of_invoices DESC

/* Q3: What are top 3 values of total invoice? */

select top(3) invoice_id, total
from invoice
order by total DESC

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city, sum(total) as sum_invoice_total
from invoice
group by billing_city
order by sum_invoice_total DESC

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer_id, sum(total) as spent_amount
from invoice
group by customer_id
order by spent_amount DESC

--Question Set 2 - Moderate

/*   Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select top (10) artist.name, count(track.track_id) as number_of_songs
from artist
join album on artist.artist_id = album.artist_id
join track on album.album_id = track.album_id
join genre on track.genre_id = genre.genre_id
where genre.name LIKE 'Rock'
group by artist.name
order by number_of_songs DESC

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
select name, milliseconds
from track
where milliseconds >
	(select avg(milliseconds) as avg
	 from track)
order by milliseconds DESC

--- Question Set 3 - Advance

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */
with cte as (
			select 
				artist.name, invoice.customer_id,
				(invoice_line.unit_price * invoice_line.quantity) as value
			from artist
			join album on artist.artist_id = album.artist_id
			join track on album.album_id = track.album_id
			join invoice_line on track.track_id = invoice_line.track_id
			join invoice on invoice_line.invoice_id = invoice.invoice_id)
select cte.name as artist_name, cte.customer_id, customer.first_name, customer.last_name, sum(cte.value) as sum_value
from cte
left join customer on cte.customer_id = customer.customer_id
group by cte.name, cte.customer_id, customer.first_name, customer.last_name
order by cte.name 

---Q2: We want to find out the most popular music Genre for each country. 
---We determine the most popular genre as the genre with the highest amount of purchases. 
---Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

with cte as (
			select invoice.billing_country, genre.name, round(sum(invoice_line.unit_price * invoice_line.quantity),2) as sum_total_price,
			row_number () over (
						partition by billing_country
						order by sum(invoice_line.unit_price * invoice_line.quantity) DESC) as row_num
			from genre
			join track on genre.genre_id = track.genre_id
			join invoice_line on track.track_id = invoice_line.track_id
			join invoice on invoice_line.invoice_id = invoice.invoice_id
			group by genre.name, invoice.billing_country
			)
select billing_country,name as Most_popular_Genre, sum_total_price
from cte
where row_num = 1

---Q3: Write a query that determines the customer that has spent the most on music for each country. 
---Write a query that returns the country along with the top customer and how much they spent. 
---For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

with cte as (
			select 
				invoice.billing_country, 
				invoice.customer_id,
				round(sum(total),2) as total_sum,
				row_number () over (
									partition by billing_country
									order by sum(total) DESC) as row_num
			from invoice
			group by invoice.billing_country , invoice.customer_id
			)
select cte.billing_country, cte.customer_id, customer.first_name, customer.last_name, total_sum as spent_amount
from cte
join customer on cte.customer_id = customer.customer_id
where row_num = 1
order by spent_amount DESC
